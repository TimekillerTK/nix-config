#!/usr/bin/env bash

# Acquire the PID of the active plasmashell
TARGET_PID=$(ps -u "tk" -f | rg plasmashell | head -n 1 | awk '{print $2}')

# Get & set needed environment variables
eval "$(tr '\0' '\n' <"/proc/${TARGET_PID}/environ" | rg 'XDG_RUNTIME_DIR|WAYLAND_DISPLAY|DBUS_SESSION_BUS_ADDRESS')"

# If ANY env var not set, exit with an error!
if [ -z "$XDG_RUNTIME_DIR" ] || [ -z "$WAYLAND_DISPLAY" ] || [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
	echo "Required environment variables not set!"
	exit 1
fi

REPO="/nix-config"
cd "$REPO" && git fetch

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse '@{u}')

ls -la

if [ "$LOCAL" != "$REMOTE" ]; then
	# notify-send works on KDE with libnotify under Wayland
	echo "Update Available - There are new updates on the remote repository."

	ls -la

	notify-send "Update Available" "There are new updates on the remote repository."
else
	echo "No updates, nothing to do."
fi

