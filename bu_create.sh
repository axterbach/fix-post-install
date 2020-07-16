#!/usr/bin/env bash

###
# Package: PostInstall Fix
# Title:   Local host backup steps
# TAGS:    [my-bash,random password generator]
# URL:     https://www.cyberciti.biz/faq/linux-unix-generating-passwords-command/
###
# Requires: Relies on pure-getop lib for command options parsing.
###
# Exit Codes: 65..110
#             [65..74] Custom system specific codes.
#                  65: Incorrect option/positional parameter.
#             [75..84] Custom script specific codes.
#                  75: MIN/MAX password length error.
#                  76: Wrong password format.
#                  84: Internal error.
###

###
# Makes debuggers' life easier - Unofficial Bash Strict Mode
# BASHDOC: Shell Builtin Commands - Modifying Shell Behavior - The Set Builtin
# Shell params:
#   -x :: Tracing/Debugging command output
#   -e :: Exit immediately on error (if a command exits with a non-zero status)
#   -u :: Treat unset variables as an error
#   -o pipefail :: Set the exit code of a pipeline to an error code
#
# Same as: +-Eux +-o pipefail
#          set +-o {errexit | errtrace | nounset | xtrace | pipefail}
###
# Extended / Advanced Globbing. Is possible that is in conflict with some
# other params (getopt in this case). So, use on your own risk.
#    extglob  :: Provides extended pattern matching (globbing)
#    failglob :: Failed patterns for pathname/dir expansion result with error
#
#    shopt -s extglob failglob ... shopt -d extglob failglob
#
# INFO: https://www.linuxjournal.com/content/bash-extended-globbing
###
#set -o errtrace
#set -o pipefail
#set -o errexit
#set -o xtrace

#set -E same as set -o errtrace

set -E -o functrace

show_usage() {
	echo
	echo "Usage"
	echo "  $0"
	echo
}

# $1=type ; $2=message
# Message types
# 0  - info
# 1  - warning
# 2  - error
# 3  - header
# 10 - normal
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
			echo -n -e "  [$clGreen+$clReset] INFO:\t$msgText"
			;;
		1)
			echo -n -e "  [$clYellow*$clReset] WARNING:\t$msgText"
			;;
		2)
			echo -n -e "  [$clRed!$clReset] ERROR:\t$msgText"
			;;
		3)
			echo -n -e "$clUnderline$msgText$clReset"
			;;
		10)
			echo -n -e "$msgText"
			;;
		*)
			echo -e "  [?] UNKNOWN:\t$msgText"
			;;
	esac
}

###
# Error/Trap handler function.
# To initiate an error use: kill -SIGINT $$
###
err_trap() {
	# Remove content from backup dir.
	rm -f "$bakPrimDir"/*

	# Resources cleanup.
	unset item tmpVal

	exit 90
}


# Captures an interrupt (signal) call error/trap handler function.
trap 'err_trap "LINENO" "BASH_LINENO" "${?}"' ERR SIGINT SIGQUIT SIGTERM

# Take command line arguments.
while [[ $# -gt 0 ]]; do
	case "${1}" in
		-h|--h|-help|--help)
			show_usage
			exit 0
			;;
		*)
			show_msg 2 "Unknown parameter \"${1}\"\n"
			exit 1
			;;
	esac
done


# Status of interactive mod, primary & secondary backup.
declare -l \
	modAutoload='no' \
	modPrimBackup='yes' \
	modSecBackup='yes'
# Path to primary/secondary backup dir.
declare -r \
	bakPrimDir="/var/backups/PIArchives" \
	bakSecDir='/media/VM_Share/192.168.1.20'
# Array of backup archive files.
declare -ar \
	bakFiles=({cober,root,system}.tar.gz)
# Content of each archive, ie. list of files/dirs.
declare -Ar bakFileCont=(
	[cober]="/home/cober/{Documents,.bash*,.face,.profile}"
	[root]="/root"
	[system]="/etc/{sudoers,hosts,hostname,resolv.conf,network/interfaces,NetworkManager/system-connections,lightdm/lightdm.conf,apt/sources.list}"
)
declare item tmpVal


###
# Wrapper function for [STAGE #2] block.
# Generates primary backup (on localhost).
###
do_stage2() {
	# Set active dir.
	cd "$bakPrimDir"

	# Refresh status msg.
	tmpVal="${bakFiles[@]}"
	show_msg 0 "Processing backup archives\n\t\t[$tmpVal]\n"
	
	# Generate TAR archive per bakFiles array values.
	# It will be something like: root.tar.gz, system.tar.gz
	# Content of each archive is defined by bakFileCont array.
	for item in "${bakFiles[@]}"; do
		eval "tar -cz -P -f $item ${bakFileCont[${item%%.*}]}"
	done

	# Refresh status msg.
	show_msg 0 "Completed\n"
}

###
# Wrapper function for [STAGE #3] block.
# Generates Secondary Backup (on NAS storage).
###
do_stage3() {
	# As first step check is NAS storage accessible.
	# If not, throw some error msg and abort.
	if ! [[ -d "$bakSecDir" ]]; then
		show_msg 2 "Storage location not accessible\n\t\t[$bakSecDir]\n"
		show_msg 0 "Abort\n"
		exit 3
	fi

	# Copy backup archives to NAS storage.
	show_msg 0 "Moving archives to NAS storage\n\t\t[$bakSecDir]\n"
	cp "$bakPrimDir"/* "$bakSecDir"
	show_msg 0 "Completed\n"
}


### STAGE #1
show_msg 3 "STAGE #1: Requirements\n"
#
# Check if the user running the script as root.
if [[ $(id -u) -ne 0 ]]; then
	show_msg 2 "You need root privileges\n"
	exit 1
fi
show_msg 0 "Root privileges granted\n"
#
# Primary backup is mandatory.
if ! [[ -d "$bakPrimDir" ]]; then
	show_msg 1 "Primary backup location not accessible ... checking\n\t\t[$bakPrimDir]\n"
	mkdir -p "$bakPrimDir"
fi
show_msg 0 "Primary backup location accessible\n"
#
# Secondary backup is not mandatory.
if ! [[ -d "$bakSecDir" ]]; then
	show_msg 1 "Secondary backup location not accessible ... skipping\n\t\t[$bakSecDir]\n"
	modSecBackup='no'
else
	show_msg 0 "Secondary backup location accessible\n"
fi
#
show_msg 0 "Ready\n"

### STAGE #2
echo
show_msg 3 "STAGE #2: Primary Backup\n"
#
# For interactive mode check user's response.
if [[ "$modAutoload" == 'no' ]]; then
	# Warning for user before critical operation.
	# Wait for response.
	show_msg 1 "Next step will destroy/overwrite existing archives\n"
	show_msg 10 "\t\tProceed anyway? [Y/n] " && read -n 2 -e -r

	# For YES proceed with primary backup.
	# For NO abort & exit.
	if [[ "$REPLY" =~ ^[Yy]{1,}$ ]]; then
		do_stage2
	else
		# For ENTER_KEY add line break before next message.
		[[ ${#REPLY} -eq 0 ]] && echo
		show_msg 0 "Abort\n"
		exit 2
	fi
# For autoload mode proceed with primary backup.
else
	do_stage2
fi

### STAGE #3
echo
show_msg 3 "STAGE #3: Secondary Backup\n"
#
# Skip secondary backup if status tels you that (for ex. dir
# location not accessible).
if [[ "$modSecBackup" == "no" ]]; then
	show_msg 0 "Skipping\n"
	exit 0
fi
# For interactive mode check user's response.
if [[ "$modAutoload" == 'no' ]]; then
	# Warning for user before critical operation.
	# Wait for response.
	show_msg 1 "Next step will destroy/overwrite existing archives\n"
	show_msg 10 "\t\tProceed anyway? [Y/n] " && read -n 2 -e -r

	# For YES proceed with secondary backup.
	# For NO abort & exit.
	if [[ "$REPLY" =~ ^[Yy]{1,}$ ]]; then
		do_stage3
	else
		# For ENTER_KEY add line break before next message.
		[[ ${#REPLY} -eq 0 ]] && echo
		show_msg 0 "Abort\n"
		exit 2
	fi
# For autoload mode proceed with secondary backup.
else
	do_stage3
fi

# Clear/Cancel interrupt (signal) calls.
trap - 0 SIGINT SIGQUIT SIGTERM

exit 0

