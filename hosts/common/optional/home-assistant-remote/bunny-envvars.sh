#!/usr/bin/env bash

umask 007 # for group write permissions

SCRIPT_DIR="/homeassistant" # directory path where the script is
max_attempts=5
delay=30
attempt=1

# for some simple logging/debugging
{
	echo "----------- bunny-envvars --------------"
	date
} >>"$SCRIPT_DIR/logfile"

# Sets username to first command line argument, otherwise
# uses default
username="${1}"
if ! id -u "$username" >/dev/null 2>&1; then
	echo "Error: User '$username' does not exist." | tee -a "$SCRIPT_DIR/logfile"
	exit 1
fi

while [ $attempt -le $max_attempts ]; do
	echo "Attempt $attempt of $max_attempts..." | tee -a "$SCRIPT_DIR/logfile"

	# Acquire the PID of the active plasmashell
	TARGET_PID=$($TOOL_PS -u "$username" -f | $TOOL_RG plasmashell | head -n 1 | $TOOL_AWK '{print $2}')

	# Get & set needed environment variables
	eval "$(tr '\0' '\n' <"/proc/${TARGET_PID}/environ" | $TOOL_RG 'XDG_RUNTIME_DIR|WAYLAND_DISPLAY|DBUS_SESSION_BUS_ADDRESS')"

	if [ -n "$XDG_RUNTIME_DIR" ] && [ -n "$WAYLAND_DISPLAY" ] && [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
		echo "All required environment variables are present, writing to \"$SCRIPT_DIR/envvars\"" | tee -a "$SCRIPT_DIR/logfile"
		# The envvars we need
		{
			echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
			echo "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
			echo "DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
		} >"$SCRIPT_DIR/envvars"
		exit 0
	fi

	if [ $attempt -lt $max_attempts ]; then
		echo "One or more variables not set, retrying after $delay seconds..." | tee -a "$SCRIPT_DIR/logfile"
		sleep $delay
	fi

	attempt=$((attempt + 1))
done

echo "Failed: required environment variables not all set after $max_attempts attempts." | tee -a "$SCRIPT_DIR/logfile"
exit 1
