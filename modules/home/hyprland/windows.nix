{ ... }:
{
  xdg.configFile."hypr/hypr_windows.lua".text = ''
    -- Make file dialogs float.
    local floatingDialogs = {
      { class = "^(file_progress)$" },
      { class = "^(confirm)$" },
      { class = "^(dialog)$" },
      { class = "^(download)$" },
      { class = "^(notification)$" },
      { class = "^(error)$" },
      { class = "^(confirmreset)$" },
      { title = "^(Open File)$" },
      { title = "^(File Upload)$" },
      { title = "^(branchdialog)$" },
      { title = "^(Confirm to replace files)$" },
      { title = "^(File Operation Progress)$" },
    }

    for _, match in ipairs(floatingDialogs) do
      hl.window_rule({ match = match, float = true })
    end

    -- Screenshare picker.
    local screensharePicker = { class = "^(xwaylandvideobridge)$" }
    hl.window_rule({ match = screensharePicker, opacity = "0.0 override" })
    hl.window_rule({ match = screensharePicker, no_anim = true })
    hl.window_rule({ match = screensharePicker, no_initial_focus = true })
    hl.window_rule({ match = screensharePicker, max_size = { 1, 1 } })
    hl.window_rule({ match = screensharePicker, no_blur = true })

    -- Remove context-menu transparency in Chromium-based apps.
    hl.window_rule({
      match = { class = "^$", title = "^$" },
      opaque = true,
      no_shadow = true,
      no_blur = true,
    })

    -- Keep the Codex avatar overlay transparent and undecorated.
    hl.window_rule({
      match = {
        class = "^(codex-desktop)$",
        initial_title = "^(Codex)$",
      },
      no_blur = true,
      no_shadow = true,
      border_size = 0,
    })

    -- Custom window rules.
    hl.window_rule({ match = { class = "(Gather)" }, workspace = "special:gather" })
    hl.window_rule({ match = { initial_title = "(YouTube Music)" }, workspace = "special:music" })

    local counterStrike = { class = "^(cs2)$" }
    hl.window_rule({ match = counterStrike, workspace = "9 silent" })
    hl.window_rule({ match = counterStrike, immediate = true })
    hl.window_rule({ match = counterStrike, border_size = 0 })
    hl.window_rule({ match = counterStrike, rounding = 0 })

    local tiledFullscreen = { float = false, workspace = "f[1]" }
    hl.window_rule({ match = tiledFullscreen, border_size = 0 })
    hl.window_rule({ match = tiledFullscreen, rounding = 0 })

    -- Layer rules.
    hl.layer_rule({
      match = { namespace = "vicinae" },
      blur = true,
      ignore_alpha = 0,
      no_anim = true,
      dim_around = true,
    })
    hl.layer_rule({
      match = { namespace = "swaync-control-center" },
      dim_around = true,
    })
    hl.layer_rule({
      match = { namespace = "noctalia-background-.*" },
      blur = true,
      blur_popups = true,
      ignore_alpha = 0.5,
    })

    -- Workspace rules.
    hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })
    hl.workspace_rule({
      workspace = "9",
      monitor = "desc:Philips Consumer Electronics Company PHL 246E9Q 0x000036F7",
    })
  '';
}
