#!/usr/bin/env bash

action="${1:-toggle}"
service=lan-mouse.service

case "$action" in
    toggle | on | off | status | gui) ;;
    *)
        echo "Usage: lan-mouse-desk [toggle|on|off|status|gui]" >&2
        exit 2
        ;;
esac

exec 9>"${XDG_RUNTIME_DIR:?}/lan-mouse-desk.lock"
flock -w 5 9

if [[ "$LAN_MOUSE_HOST" == atlas ]]; then
    label=Sharing
    enabled_message="Move past the left edge to control Zephyrus."
else
    label=Receiver
    enabled_message="Atlas can control this laptop while sharing is enabled on Atlas."
fi

notify() {
    notify-send --app-name="Lan Mouse" "Lan Mouse: $label $1" "$2" || true
}

is_running() {
    systemctl --user is-active --quiet "$service"
}

start_sharing() {
    if is_running; then
        return
    fi
    if systemctl --user start "$service" && is_running; then
        notify on "$enabled_message"
    else
        notify "could not start" "Check journalctl --user -u lan-mouse -b."
        echo "Lan Mouse did not start; check journalctl --user -u lan-mouse -b." >&2
        return 1
    fi
}

stop_sharing() {
    systemctl --user stop "$service"
    notify off "This computer's keyboard and mouse are local."
}

case "$action" in
    toggle)
        if is_running; then
            stop_sharing
        else
            start_sharing
        fi
        ;;
    on) start_sharing ;;
    off) stop_sharing ;;
    status)
        if is_running; then
            echo "$label on"
        else
            echo "$label off"
        fi
        ;;
    gui)
        start_sharing
        # The GUI attaches to the service. Do not hold the toggle lock open
        # while the pairing window is open.
        flock -u 9
        exec 9>&-
        exec lan-mouse --config "$LAN_MOUSE_CONFIG"
        ;;
esac
