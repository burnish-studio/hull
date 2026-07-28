# The interactive shell: zsh, its prompt, and history/file search.
#
# Everything here is expressed as Home Manager options, so it is generated into
# the Nix store and takes effect on rebuild. Nothing in this module is edited
# live — that distinction matters, see modules/paths.nix.
#
# Setting `programs.zsh.enable` here does NOT make zsh the login shell; that is
# a NixOS-level fact about the user account and lives in hosts/<host>.nix.
{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true; # ghost text from history
    syntaxHighlighting.enable = true; # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    # Phase 3 adds one generated function per account here (v1's `accountCommand`
    # in hull-fedora/home.nix) — it needs registry data, so it is not ported yet.
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      # High-agency agent shortcut. Understand exactly what
      # --dangerously-skip-permissions does before enabling this.
      # cc = "claude --dangerously-skip-permissions";
    };
  };

  # Ctrl-R history search / Ctrl-T file search. Installs fzf and wires the zsh
  # keybindings, so fzf is not listed again in the tools module.
  programs.fzf.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };
}
