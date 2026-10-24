{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  island = "${config.services.island.package}/bin/island";
  screenshotRegion = pkgs.writeShellApplication {
    name = "screenshot-region";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
    ];
    text = ''
      geometry="$(slurp)" || exit 0
      [[ -n "$geometry" ]] || exit 0

      screenshot="$(mktemp --suffix=.png)"
      trap 'rm -f "$screenshot"' EXIT
      grim -g "$geometry" "$screenshot"
      wl-copy --type image/png < "$screenshot"
    '';
  };
in
{
  xdg.configFile."hypr/hypr_binds.lua".text = ''
    local mainMod = "SUPER"

    hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("alacritty"))
    hl.bind(mainMod .. " + C", hl.dsp.window.close())
    hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("${island} launcher toggle"))
    hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("${island} session toggle"))
    hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))

    -- Move focus with mainMod + vim keys.
    hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "l" }))
    hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "r" }))
    hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "u" }))
    hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "d" }))

    -- Switch workspaces and move the active window with mainMod + [0-9].
    for i = 1, 10 do
      local key = i % 10
      hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
      hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end

    hl.bind("CTRL + SHIFT + Space", hl.dsp.exec_cmd("1password --quick-access"))

    -- Toggle sharing on Atlas, or the receiver on Zephyrus.
    hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("lan-mouse-desk"))

    ${lib.optionalString (host == "atlas") ''
      hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("atlas-remote toggle"))
      -- A local recovery key also works while the desktop is locked.
      hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("atlas-remote off"), { locked = true })
    ''}

    -- Focus monitors from left to right with U, I, O.
    ${lib.optionalString (host == "atlas") ''
      hl.bind(mainMod .. " + U", hl.dsp.focus({ monitor = "desc:Philips Consumer Electronics Company PHL 246E9Q 0x000036F7" }))
    ''}
    ${lib.optionalString (host == "zephyrus") ''
      hl.bind(mainMod .. " + U", hl.dsp.focus({ monitor = "desc:Sharp Corporation LQ160R1JW02" }))
    ''}
    hl.bind(mainMod .. " + I", hl.dsp.focus({ monitor = "${
      if host == "atlas" then
        "desc:AOC Q27G4ZR"
      else
        "desc:Philips Consumer Electronics Company PHL 246E9Q 0x000036F7"
    }" }))
    hl.bind(mainMod .. " + O", hl.dsp.focus({ monitor = "desc:Shenzhen KTC Technology Group PMO G241-FFK" }))

    -- Special workspace (scratchpad).
    hl.bind(mainMod .. " + m", hl.dsp.workspace.toggle_special("magic"))
    hl.bind(mainMod .. " + SHIFT + m", hl.dsp.window.move({ workspace = "special:magic" }))
    hl.bind(mainMod .. " + n", hl.dsp.workspace.toggle_special("gather"))
    hl.bind(mainMod .. " + SHIFT + n", hl.dsp.window.move({ workspace = "special:gather" }))

    -- Scroll through existing workspaces.
    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

    -- Select a region with slurp, capture with grim, and copy it to the clipboard.
    hl.bind("Print", hl.dsp.exec_cmd("${screenshotRegion}/bin/screenshot-region"))

    -- Reveal or hide Island's bar over fullscreen windows.
    hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("${island} bar toggle"))

    -- Dictation.
    hl.bind("Insert", hl.dsp.exec_cmd("pkill -USR2 -n handy"))
    hl.bind("SHIFT + Insert", hl.dsp.exec_cmd("handy --toggle-post-process"))

    local repeatingLocked = { repeating = true, locked = true }
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), repeatingLocked)
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), repeatingLocked)
    hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), repeatingLocked)
    hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), repeatingLocked)
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), repeatingLocked)

    local locked = { locked = true }
    hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), locked)
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), locked)
    hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), locked)
    hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), locked)

    -- Mouse bindings.
    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- T3 Code
    hl.bind(mainMod .. " + s", hl.dsp.global("com.t3tools.T3Code:capture-window"))
  '';
}
