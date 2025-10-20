#!/usr/bin/env bash

export STATE=/home/tk/.local/state/alacritty-dropdown

# Uncomment for testing (running script raw)
# export KDOTOOL=/nix/store/c9kb7slpi20qw2a9ch2gfp7p9nmpjg62-kdotool-0.2.2-pre/bin/kdotool
# export ALACRITTY=alacritty

if [ -z "$($KDOTOOL search --class alacritty)" ]; then
	$ALACRITTY &
	sleep 0.5

	$KDOTOOL search --class alacritty windowstate --add SKIP_TASKBAR windowstate --add FULLSCREEN --toggle ABOVE
	echo 1 >$STATE
fi

echo "State is: $STATE"
if [[ $(<$STATE) == 1 ]]; then
	echo "Setting Window Below"
	$KDOTOOL search --class alacritty windowstate --toggle BELOW
	echo 0 >$STATE
else
	echo "Setting Window Above"
	$KDOTOOL search --class alacritty windowstate --add SKIP_TASKBAR windowstate --add FULLSCREEN --toggle ABOVE
	echo 1 >$STATE
fi
