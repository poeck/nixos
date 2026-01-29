{ config, pkgs, ... }:
{
  config.programs.nixvim.keymaps = [
    {
      key = "<leader>1";
      action = "<Cmd>BufferGoto 1<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>2";
      action = "<Cmd>BufferGoto 2<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>3";
      action = "<Cmd>BufferGoto 3<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>4";
      action = "<Cmd>BufferGoto 4<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>5";
      action = "<Cmd>BufferGoto 5<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>6";
      action = "<Cmd>BufferGoto 6<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>7";
      action = "<Cmd>BufferGoto 7<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>8";
      action = "<Cmd>BufferGoto 8<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>9";
      action = "<Cmd>BufferGoto 9<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>m";
      action = ":";
      mode = "";
      options.silent = true;
    }
    {
      key = "<leader>o";
      action = ":ex ~/";
      mode = "";
      options.silent = true;
    }
    {
      key = "<C-c>";
      action = ":noh<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<S-q>";
      action = ":qa!<CR>";
      mode = "";
      options.silent = true;
    }
    {
      key = "<leader>s";
      action = ":silent write<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "jk";
      action = "<ESC>";
      mode = "i";
    }
    {
      key = "<c-s>";
      action = "<Esc>:w<CR>a";
      mode = "i";
    }
    {
      key = "<S-h>";
      action = "0";
      mode = "v";
    }
    {
      key = "<S-l>";
      action = "$";
      mode = "v";
    }
    {
      key = "<Tab>";
      action = ">gv";
      mode = "v";
    }
    {
      key = "<S-Tab>";
      action = "<gv";
      mode = "v";
    }
    {
      key = "<leader><space>";
      action = "<cmd>Telescope find_files<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>fg";
      action = "<cmd>Telescope live_grep<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>fh";
      action = "<cmd>Telescope help_tags<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>fj";
      action = "<cmd>Telescope buffers<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>fl";
      action = ":Oil --float<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>bf";
      action = "<cmd>Telescope buffers<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>bb";
      action = "<cmd>Telescope buffers<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>bc";
      action = "<Cmd>BufferClose<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>bd";
      action = "<Cmd>BufferClose<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>bP";
      action = "<Cmd>BufferPin<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>ff";
      action = "<cmd>Telescope live_grep<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "[b";
      action = "<Cmd>BufferPrevious<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "]b";
      action = "<Cmd>BufferNext<CR>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>h";
      action = "<C-w>h";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>j";
      action = "<C-w>j";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>k";
      action = "<C-w>k";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>l";
      action = "<C-w>l";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>wv";
      action = "<C-w>v";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>wh";
      action = "<C-w>s";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>ws";
      action = "<C-w>s";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>wd";
      action = "<C-w>c";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>wc";
      action = "<C-w>c";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>wq";
      action = "<C-w>c";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>rr";
      action.__raw = "function() vim.cmd('source $MYVIMRC') end";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>gg";
      action.__raw = "function() vim.cmd('tab G') end";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>gb";
      action.__raw = "function() vim.cmd('Git blame') end";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>ga";
      action.__raw = "function() vim.cmd('G add .') end";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>gp";
      action.__raw = "function() vim.cmd('G push') end";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>gc";
      action.__raw = "function() require('telescope').extensions.conventional_commits.conventional_commits({ include_body_and_footer = true }) end";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>y";
      action.__raw = "function() vim.cmd('!xdg-open %') end";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>x";
      action.__raw = "function() vim.cmd('!xdg-open %:h') end";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<Esc>";
      action = ":if &filetype ==# 'fzf' | execute 'normal! \\<Esc>' | else | execute 'normal! \\<c-\\>\\<c-n>' | endif<CR>";
      mode = "t";
    }
    {
      key = "jk";
      action = ":if &filetype ==# 'fzf' | execute 'normal! \\<Esc>' | else | execute 'normal! \\<c-\\>\\<c-n>' | endif<CR>";
      mode = "t";
    }
    {
      key = "<leader>xx";
      action = "<cmd>TroubleToggle<cr>";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>cp";
      action = "\"+y";
      mode = "v";
      options.silent = true;
    }
    {
      key = "<leader>cp";
      action = "\"+yy";
      mode = "n";
      options.silent = true;
    }
    {
      key = "<leader>cP";
      action = "\"+Y";
      mode = "n";
      options.silent = true;
    }
  ];

  config.programs.nixvim.keymapsLua = [ ];
}

