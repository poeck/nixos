# Called by the root system service. Arguments also permit isolated tests.
set -eu
marker="$1"
unit_directory="$2"
changed=0
for target in poweroff.target halt.target; do
  directory="$unit_directory/$target.d"
  dropin="$directory/90-atlas-remote-guard.conf"
  if [ -e "$marker" ]; then
    if [ ! -f "$dropin" ]; then
      mkdir -p "$directory"
      printf '[Unit]\nRefuseManualStart=yes\n' > "$dropin.tmp"
      mv "$dropin.tmp" "$dropin"
      changed=1
    fi
  elif [ -f "$dropin" ]; then
    rm "$dropin"
    # Other administrators' drop-ins must remain untouched.
    rmdir "$directory" 2>/dev/null || true
    changed=1
  fi
done
if [ "$changed" = 1 ]; then
  systemctl daemon-reload
fi
