#!/usr/bin/env bash
REPO="/nix-config"
cd "$REPO" && git fetch

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse '@{u}')

if [ "$LOCAL" != "$REMOTE" ]; then
	# Notify-send works on KDE with libnotify under Wayland
	notify-send "Update Available" "There are new updates on the remote repository."
else
	echo "No updates, nothing to do."
fi
