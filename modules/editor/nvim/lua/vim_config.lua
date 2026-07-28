local o = vim.opt
vim.g.mapleader = ' '            -- space is the leader key
o.expandtab = true              -- spaces, not tabs
o.shiftwidth = 2                -- 2 spaces per indent level
o.number = true                 -- absolute number on the cursor line
o.relativenumber = true         -- relative line numbers for fast jumps
o.ignorecase = true             -- search is case-insensitive by default
o.smartcase = true              -- case-sensitive only if you type a capital
o.clipboard = 'unnamedplus'     -- share the system clipboard
o.scrolloff = 16                -- keep cursor away from the screen edge
o.undofile = true               -- persistent undo across sessions

-- Clipboard providers differ per environment:
--   * native Linux desktop -> wl-clipboard (installed on the laptop host)
--   * WSL -> bridge to the Windows clipboard via clip.exe / powershell.exe
if vim.fn.has('wsl') == 1 then
  vim.g.clipboard = {
    name = 'WslClipboard',
    copy = {
      ['+'] = 'clip.exe',
      ['*'] = 'clip.exe',
    },
    paste = {
      ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
      ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
    },
    cache_enabled = 0,
  }
end
