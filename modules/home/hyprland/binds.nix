{ ... }:
{
  xdg.configFile."hypr/hypr_binds.lua".text = ''
    local mainMod = "SUPER"

    hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("alacritty"))
    hl.bind(mainMod .. " + C", hl.dsp.window.close())
    hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("vicinae toggle"))
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

    hl.bind(mainMod .. " + U", hl.dsp.focus({ monitor = "desc:Sharp Corporation LQ160R1JW02" }))
    hl.bind(mainMod .. " + I", hl.dsp.focus({ monitor = "desc:Philips Consumer Electronics Company PHL 246E9Q 0x000036F7" }))
    hl.bind(mainMod .. " + O", hl.dsp.focus({ monitor = "desc:Shenzhen KTC Technology Group PMO G241-FFK" }))

    -- Special workspace (scratchpad).
    hl.bind(mainMod .. " + m", hl.dsp.workspace.toggle_special("magic"))
    hl.bind(mainMod .. " + SHIFT + m", hl.dsp.window.move({ workspace = "special:magic" }))

    hl.bind(mainMod .. " + n", hl.dsp.exec_cmd("swaync-client -t"))

    -- Scroll through existing workspaces.
    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

    -- Screenshots.
    hl.bind("Print", hl.dsp.exec_cmd("screenshot --copy"))
    hl.bind("SHIFT + Print", hl.dsp.exec_cmd("screenshot --save"))

    -- Toggle the Noctalia bar.
    hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("noctalia msg bar-toggle"))

    -- Dictation.
    hl.bind("Insert", hl.dsp.exec_cmd("handy --toggle-transcription"))
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
  '';
}
