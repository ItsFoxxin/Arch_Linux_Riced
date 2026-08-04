#!/usr/bin/env bash

set -u

THEME="$HOME/.config/waybar/foxden-launcher.rasi"
SCRIPTS="$HOME/.config/waybar/scripts"

show_menu() {
	local prompt="$1"
	shift

	printf '%s\n' "$@" |
		rofi \
			-dmenu \
			-i \
			-p "$prompt" \
			-theme "$THEME"
}

confirm_action() {
	local action="$1"
	local answer

	answer="$(
		show_menu \
			"Confirm $action" \
			"Cancel" \
			"$action"
	)"

	[[ "$answer" == "$action" ]]
}

notify_power_action() {
	local message="$1"

	if command -v notify-send >/dev/null 2>&1; then
		notify-send \
			--app-name="Fox Den" \
			--urgency=critical \
			--expire-time=5000 \
			"Power & Sessions" \
			"$message"
	fi
}

run_power_command() {
	local action="$1"
	shift

	logger --tag foxden-launcher \
		"Power action confirmed: $action; command: $*"

	notify_power_action "$action starting now"

	"$@"
}

power_menu() {
	local choice

	choice="$(
		show_menu \
			"Power & Session" \
			"Lock" \
			"Suspend" \
			"Restart" \
			"Shut down"
	)"

	case "$choice" in
		"Lock")
			confirm_action "Lock" || return 0
			
			notify_power_action "Locking session"
			
			if command -v hyprlock >/dev/null 2>&1; then
				hyprlock >/dev/null 2>&1 &

			else
				loginctl lock-session

			fi
			;;

		"Suspend")
			confirm_action "Suspend" || return 0
			run_power_command "Suspend" systemctl suspend
			;;

		"Restart")
			confirm_action "Restart" || return 0
			run_power_command "Restart" systemctl reboot
			;;

		"Shut down")
			confirm_action "Shut down" || return 0
			run_power_command "Shut down" systemctl poweroff
			;;
	esac
}

selection="$(
	show_menu \
		"Fox Den" \
		"Applications" \
		"Windows" \
		"Terminal" \
		"Quick Controls" \
		"Power & Sessions" \
)"

case "$selection" in
	"Applications")
		rofi \
			-show drun \
			-theme "$THEME"
		;;
	
	"Windows")
		rofi \
			-show window \
			-theme "$THEME"
		;;
	
	"Terminal")
		setsid -f kitty >/dev/null 2>&1
		;;

	"Quick Controls")
		sleep 0.15
		"$SCRIPTS/quick-controls.sh"
		;;

	"Power & Sessions")
		power_menu
		;;
esac
