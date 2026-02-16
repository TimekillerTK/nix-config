#!/usr/bin/env bash

# Directory path where the script is
SCRIPT_DIR="/homeassistant"

# for some simple logging/debugging
{
	echo "--------- bunny-script -------------"
	date
} >>"$SCRIPT_DIR/logfile"

# Sets username to first command line argument, otherwise
# uses default
check_user_exists() {
	username=$BUNNY_USER
	if ! id -u "$username" >/dev/null 2>&1; then
		echo "Error: User '$username' does not exist." | tee -a "$SCRIPT_DIR/logfile"
		exit 1
	fi
}

# Function to display the message box
display_message() {
	# Path to your custom image
	IMAGE_PATH="bunny.png"

	# HTML content for the dialog
	HTML_CONTENT="
    <html>
    <body style='text-align: center;'>
        <h2 style='color: red;'>System Shutdown Warning</h2>
        <p style='font-size: 16px;'><strong>WARNING: Your computer will shut down in 5 minutes.</strong></p>
        <p style='font-size: 14px;'>Please save all your work and close any open applications.</p>
        <p style='font-size: 14px;'>Press OK to acknowledge.</p>
        <div style='margin-top: 20px;'>
            <img src='file://$SCRIPT_DIR/$IMAGE_PATH' width='300' height='200' style='display: block; margin: 0 auto;'>
        </div>
    </body>
    </html>"

	# Acquire environment variables which we need to run the command
	eval $(cat "$SCRIPT_DIR/envvars")

	# for some simple debugging
	{
		echo "Username is: $username"
		echo "$XDG_RUNTIME_DIR"
		echo "$WAYLAND_DISPLAY"
		echo "$DBUS_SESSION_BUS_ADDRESS"
	} | tee -a "$SCRIPT_DIR/logfile"

	# Actually run the command for the dialog
	sudo -u "$BUNNY_USER" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
		WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
		DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS" \
		"$TOOL_KDIALOG" --title "System Shutdown" --msgbox "$HTML_CONTENT"
}

check_user_exists

minutes="5"
sudo shutdown -h +''${minutes} "System will shut down in $minutes minutes"
echo "Shutdown scheduled. The system will shut down in $minutes minutes." | tee -a "$SCRIPT_DIR/logfile"

# Display the message box
display_message
