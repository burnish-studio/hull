#!/usr/bin/env bash
# Claude Code status line.
# Reads session JSON on stdin, prints one status line.
#
# Ported from hull-fedora 2026-07-28. The v1 version parsed the session JSON
# with python3, on the stated assumption that "jq is not guaranteed on this
# machine" and python3 is "stable at /usr/bin/python3". On NixOS both halves are
# false in the opposite direction: there is no /usr/bin/python3 and no python3 on
# PATH at all, while jq IS declared in modules/tools. So the parse is jq now.

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf 'statusline: jq not found on PATH'
  exit 0
fi

# One jq pass, one field per line in a fixed order so the array indices below
# stay stable. Missing fields come back as empty strings, never absent lines.
# Note 0 is a legitimate value: jq's // only falls through on null/false, so a
# genuine 0% is preserved rather than blanked.
mapfile -t _fields < <(printf '%s' "$input" | jq -r '
  [
    (.model.display_name // ""),
    (.workspace.current_dir // .cwd // ""),
    (.output_style.name // ""),
    (if ((.workspace.repo.owner // "") != "") and ((.workspace.repo.name // "") != "")
     then "\(.workspace.repo.owner)/\(.workspace.repo.name)" else "" end),
    (.context_window.used_percentage // "" | tostring),
    (.rate_limits.five_hour.used_percentage // "" | tostring),
    (.rate_limits.seven_day.used_percentage // "" | tostring),
    (.vim.mode // "")
  ] | .[]
' 2>/dev/null)

model="${_fields[0]:-}"
cwd="${_fields[1]:-}"
output_style="${_fields[2]:-}"
repo="${_fields[3]:-}"
ctx_used="${_fields[4]:-}"
five_hour="${_fields[5]:-}"
seven_day="${_fields[6]:-}"
vim_mode="${_fields[7]:-}"

# v1 also read context_window.remaining_percentage and never used it - remaining
# is just 100 - used. Dropped rather than carried.

dir=""
[ -n "$cwd" ] && dir=$(basename "$cwd")

# --- Git branch (skip optional locks: read-only, don't block other git ops) ---
branch=""
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
fi

# --- Active gh identity ------------------------------------------------------
# Shows whichever account `gh` is currently authenticated as, whatever it is.
#
# Deliberately NOT mapped to short labels. v1 had a case statement translating
# `burnish-studio` -> `burnish` and `flintec-studio` -> `flintec`; that is
# identity data, and hull is identity-agnostic (ADR 0002) and public. Printing
# the login verbatim costs a few characters of width and hardcodes nothing, so
# this file works unchanged for any account on any machine.
#
# If short display labels are wanted later, the registry is where they belong -
# it already holds the per-account aliases (D1.5) and is private.
#
# Read from gh's own local state rather than the API. v1 ran
# `timeout 1 gh api user`, cached for 30s. Measured on this machine 2026-07-28,
# that call takes ~1.06s consistently, so the 1s timeout killed it every single
# time and the segment silently vanished once the cache expired. Raising the
# timeout would have fixed the symptom and kept a network round-trip inside a
# status line that renders constantly.
#
# `user:` under the host in hosts.yml is exactly what `gh auth switch` rewrites,
# so this is the same fact, read locally: no network, no timeout, no cache, and
# no stale window after a switch. It also means the status line no longer needs
# `gh` on PATH at all. If gh ever changes the file's shape the segment just
# disappears, which is a visible and harmless failure.
GH_HOSTS="${GH_CONFIG_DIR:-$HOME/.config/gh}/hosts.yml"
identity=$(awk -F': *' '/^[[:space:]]{4}user:[[:space:]]/ { print $2; exit }' \
  "$GH_HOSTS" 2>/dev/null)

# --- Colors: 24-bit truecolor (both WezTerm and Windows Terminal support it).
# Truecolor bypasses each terminal's 16-color theme palette, so these read the
# same in both - unlike dim ANSI codes, which the theme remaps (that is why dim
# dark-blue was muddy on Windows Terminal). Palette chosen to stay legible on a
# dark background. ---
RESET='\033[0m'
DIM='\033[38;2;110;118;129m'      # grey - separators / de-emphasized
C_MODEL='\033[38;2;121;218;218m'  # teal
C_DIR='\033[38;2;108;182;255m'    # light blue
C_GIT='\033[38;2;126;231;135m'    # green
C_CTX='\033[38;2;227;179;65m'     # amber
C_RATE='\033[38;2;210;168;255m'   # lavender
C_ID='\033[38;2;255;123;114m'     # soft red

# --- Icons (Nerd Font glyphs) ------------------------------------------------
# Requires a Nerd Font as the terminal's font face. hull's font is **JetBrainsMono
# Nerd Font**, chosen by the captain 2026-07-28: it is what is already installed
# on the Windows side, it renders these glyphs correctly (verified live), and it
# was the easier one to obtain. Phase 6 should use `nerd-fonts.jetbrains-mono`
# for the native host so both host types agree.
#
# Note the ported `wezterm.lua` in hull-fedora says `Hack Nerd Font` - that came
# from Kun and describes the laptop's wezterm, not this terminal. Two terminals,
# two fonts; the v1 comment naming JetBrainsMono was right about its own context.
# Phase 6 resolves it by moving wezterm to JetBrainsMono too.
#
# On WSL the font is installed on the Windows side by hand - hull never touches
# Windows. If these render as empty boxes the font is missing; set
# CLAUDE_STATUSLINE_ICONS=0 for text labels instead.
#
# All codepoints are from the Material-Design block (Plane 15, U+F0000+), NOT the
# lower BMP private-use area (E000-F8FF). Windows' own icon fonts (Segoe MDL2 /
# Fluent Icons) squat on BMP-PUA, so Windows Terminal resolves glyphs there to a
# blank system glyph instead of the Nerd Font. Plane 15 is above that collision.
USE_ICONS="${CLAUDE_STATUSLINE_ICONS:-1}"
if [ "$USE_ICONS" = "1" ]; then
  I_MODEL="$(printf '\U000F06A9')"   # md-robot
  I_DIR="$(printf '\U000F024B')"     # md-folder
  I_GIT="$(printf '\U000F062C')"     # md-source-branch
  I_CTX="$(printf '\U000F029A')"     # md-gauge
  I_RATE="$(printf '\U000F0150')"    # md-clock
  I_ID="$(printf '\U000F02A4')"      # md-github
  I_MODEL="$I_MODEL " I_DIR="$I_DIR " I_GIT="$I_GIT " I_CTX="$I_CTX " I_RATE="$I_RATE " I_ID="$I_ID "
else
  I_MODEL='' I_DIR='' I_GIT='' I_CTX='' I_RATE='' I_ID=''
fi

segments=()

[ -n "$model" ] && segments+=("$(printf "${C_MODEL}${I_MODEL}%s${RESET}" "$model")")
[ -n "$dir" ] && segments+=("$(printf "${C_DIR}${I_DIR}%s${RESET}" "$dir")")

if [ -n "$repo" ] || [ -n "$branch" ]; then
  if [ -n "$repo" ] && [ -n "$branch" ]; then
    gitstr="${repo} (${branch})"
  else
    gitstr="${repo}${branch}"
  fi
  segments+=("$(printf "${C_GIT}${I_GIT}%s${RESET}" "$gitstr")")
fi

if [ -n "$ctx_used" ]; then
  [ "$USE_ICONS" = "1" ] && ctx_label="" || ctx_label="ctx "
  segments+=("$(printf "${C_CTX}${I_CTX}${ctx_label}%.0f%%${RESET}" "$ctx_used")")
fi

rate=""
[ -n "$five_hour" ] && rate="5h:$(printf '%.0f' "$five_hour")%"
if [ -n "$seven_day" ]; then
  [ -n "$rate" ] && rate="$rate "
  rate="${rate}7d:$(printf '%.0f' "$seven_day")%"
fi
[ -n "$rate" ] && segments+=("$(printf "${C_RATE}${I_RATE}%s${RESET}" "$rate")")

extras=""
[ -n "$output_style" ] && [ "$output_style" != "default" ] && extras="$output_style"
if [ -n "$vim_mode" ]; then
  [ -n "$extras" ] && extras="$extras "
  extras="${extras}[$vim_mode]"
fi
[ -n "$extras" ] && segments+=("$(printf "${DIM}%s${RESET}" "$extras")")

if [ -n "$identity" ]; then
  [ "$USE_ICONS" = "1" ] && id_label="" || id_label="gh:"
  segments+=("$(printf "${C_ID}${I_ID}${id_label}%s${RESET}" "$identity")")
fi

out=""
sep="$(printf "${DIM} | ${RESET}")"
for seg in "${segments[@]}"; do
  if [ -z "$out" ]; then
    out="$seg"
  else
    out="${out}${sep}${seg}"
  fi
done

printf "%b" "$out"
