#!/usr/bin/env bash

show_usage() {
	echo
	echo "Usage"
	echo "  $0"
	echo
}

# $1=type ; $2=message
# Message types
# 0 - info
# 1 - warning
# 2 - error
# 3 - header
show_msg() {
	local -r \
		clRed="\e[31m" \
		clGreen="\e[32m" \
		clYellow="\e[33m" \
		clUnderline="\e[4m" \
		clReset="\e[0m" \
		msgType="${1}" \
		msgText="${2}"

	if [[ -z "$msgType" || -z "$msgText" ]]; then
		return
	fi

	case "$msgType" in
		0)
			echo -e "  [$clGreen+$clReset] INFO:\t$msgText"
			;;
		1)
			echo -e "  [$clYellow*$clReset] WARNING:\t$msgText"
			;;
		2)
			echo -e "  [$clRed!$clReset] ERROR:\t$msgText"
			;;
		3)
			echo -e "$clUnderline$msgText$clReset"
			;;
		*)
			echo -e "  [?] UNKNOWN:\t$msgText"
			;;
	esac
}

# Take command line arguments.
while [[ $# -gt 0 ]]; do
	case "${1}" in
		-h|--h|-help|--help)
			show_usage
			exit 0
			;;
		*)
			show_msg 2 "Unknown parameter \"${1}\""
			exit 1
			;;
	esac
done

### STAGE #1
show_msg 3 "STAGE #1: Requirements"
#
# Check if the user running the script is root.
if [[ $(id -u) -ne 0 ]]; then
	show_msg 2 "You need root privileges."
	exit 1
fi
show_msg 0 "You have root privileges."
#
if ! ping -c 3 -q google.com 1>/dev/null; then
#if [[ $? -ne 0 ]]; then
	show_msg 2 "You need internet connection."
	exit 1
fi
show_msg 0 "You have internet connection."
#
if ! command -v apt 1>/dev/null; then
	show_msg 2 "Package manager (apt) not found."
	exit 1
fi
show_msg 0 "Package manager (apt) found."
#
if ! [[ -f /media/cdrom/autorun.sh ]]; then
	show_msg 2 "Guest Additions CD not found.\n\t\tGo to Devices -> Insert Guest Additions CD... and try again."
	exit 1
fi
show_msg 0 "Guest Additions CD is found."

### STAGE #2
echo
show_msg 3 "STAGE #2: System update"
#
apt update && apt upgrade
if [[ $? -ne 0 ]]; then
	show_msg 2 "System is not updated."
	exit 1
fi
show_msg 0 "System updated."

### STAGE #3
echo
show_msg 3 "STAGE #3: Additional Software"
#
apt install "linux-headers-$(uname -r)"
if [[ $? -ne 0 ]]; then
	show_msg 2 "Applications are not installed."
	exit 1
fi
show_msg 0 "Applications are installed."

### STAGE #4
echo
show_msg 3 "STAGE #4: Guest Additions"
#
sh /media/cdrom0/autorun.sh
show_msg 0 "Guest Additions are installed."

### STAGE #5
echo
show_msg 3 "STAGE #5: User Account"
#
adduser cober vboxsf 1>/dev/null
show_msg 0 "'cober' added to 'vboxsf' group."

### STAGE #6
echo
show_msg 3 "STAGE #6: Reboot"
#
show_msg 0 "All done. Reboot your VM now"
