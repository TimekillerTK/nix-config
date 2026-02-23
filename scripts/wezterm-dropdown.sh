#!/usr/bin/env bash

export STATE=/home/tk/.local/state/wezterm-dropdown

# Uncomment for testing (running script raw)
# export KDOTOOL=/nix/store/c9kb7slpi20qw2a9ch2gfp7p9nmpjg62-kdotool-0.2.2-pre/bin/kdotool
# export WEZTERM=wezterm

if [ -z "$($KDOTOOL search --class wezterm)" ]; then
	$WEZTERM &
	sleep 0.5

	$KDOTOOL search --class wezterm windowstate --add SKIP_TASKBAR windowstate --add FULLSCREEN --toggle ABOVE
	echo 1 >$STATE
fi

echo "State is: $STATE"
if [[ $(<$STATE) == 1 ]]; then
	echo "Setting Window Below"
	$KDOTOOL search --class wezterm windowstate --toggle BELOW
	echo 0 >$STATE
else
	echo "Setting Window Above"
	$KDOTOOL search --class wezterm windowstate --add SKIP_TASKBAR windowstate --add FULLSCREEN --toggle ABOVE
	echo 1 >$STATE
fi
