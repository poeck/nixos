{ config, pkgs, ... }:
{
  config.programs.nixvim.opts = {
    ignorecase = true;
    smartcase = true;
    relativenumber = true;
    expandtab = true;
    smarttab = true;
    autoindent = true;
    smartindent = true;
    cindent = true;
    showmode = false;
    timeout = false;
    writebackup = false;
    hidden = true;
    list = true;
    listchars = "tab:▸ ,trail:·";
    scrolloff = 8;
    sidescrolloff = 8;
    laststatus = 2;
    softtabstop = 4;
    shiftwidth = 4;
    tabstop = 4;
    background = "dark";
    termguicolors = true;
    updatetime = 300;
    timeoutlen = 1000;
    ttimeoutlen = 0;
    mouse = "";
  };
}

