{ ... }:
{
  xdg.configFile."hypr/hypr_exec_once.lua".text = ''
    hl.on("hyprland.start", function()
      local commands = {
        -- Import the compositor environment and start Home Manager's
        -- Hyprland session target. The legacy Home Manager config injected
        -- this automatically, so Lua configs need to retain it explicitly.
        "dbus-update-activation-environment --systemd --all && systemctl --user stop hyprland-session.target && systemctl --user start hyprland-session.target",
        -- Allow programs to request elevated privileges.
        "systemctl --user start hyprpolkitagent",

        -- Auto suspend and lock.
        "hypridle",
        -- Status bar / shell.
        "noctalia",
        -- Notification center and Wi-Fi tray.
        "swaync",
        "nm-applet",
        -- Wallpaper.
        "swaybg -i ${../../../wallpaper.jpg}",
        -- Auto mount external drives.
        "udiskie --automount --notify --smart-tray &",
        -- Cursor.
        "hyprctl setcursor Bibata-Modern-Ice 24 &",
        -- Clipboard.
        "wl-clip-persist --clipboard both &",
        "wl-paste --watch cliphist store &",
        -- Password manager.
        "1password --silent",
        -- Speech-to-text.
        "handy --start-hidden",
        -- Best backup tool.
        "blinkdisk --hidden",
      }

      for _, command in ipairs(commands) do
        hl.exec_cmd(command)
      end
    end)
  '';
}
