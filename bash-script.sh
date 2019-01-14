#!/usr/bin/env bash

# grab system vars and store them in VARS
VARS=`set -o posix ; set`

# REQUIRED: important global variables
ENV="prod"										# environment (prod, dev, test)
MINARGS=0										# minimum number of cli arguments
DEBUG=off										# Debug output? (on/off)
INFO=off										# Informational output? (on/off)
TMPFILE=$(mktemp /tmp/myfile.XXXXX)				# create a tmp file
LOGFILE=/var/log/someapp.log 					# name of log file to use

# SYSTEM: time and dates to construct filenames
US_DATE=`date +%d%m%Y`							# US formatted date
EU_DATE=`date +%Y%m%d`							# EU formatted date
NOW=`date +%H%M`								# The time at start of script

# OPTIONAL: required programs
REQUIRED_PROGS=(bash ssh)

# REQUIRED COMMAND MAPPINGS:
RM=$(which rm);			FIND=$(which find); 		ECHO=$(which echo);		TPUT=$(which tput);
PS=$(which ps);			GREP=$(which grep); 		SSH=$(which ssh);       WGET=$(which wget); 	
CURL=$(which curl);		PING=$(which ping);

#
# BEGIN FUNCTIONS SECTION:
# function debug() 			# echo debug information to screen and log if DEBUG is set to on
# 	usage: debug "the program broke"
#
function debug(){
	local msg="[debug] - $1"
	[ "$DEBUG" == "on" ] && $ECHO $msg
	[ "$DEBUG" == "on" ] && $ECHO $msg >> $LOGFILE
	return
 }

# function info() 			# post info to screen and log if INFO is set to on
# 	usage: info "text to output in case INFO is on"
#
function info(){
	local msg="[info] - $1"
	[ "$INFO" == "on" ] && $ECHO $msg
	[ "$INFO" == "on" ] && $ECHO $msg >> $LOGFILE
	return
}

# function cleanup() 		# run a cleanup before exiting
#	usage: cleanup
#
function cleanup(){
	debug "Starting cleanup..."
	# isset?
	$RM -f $TMPFILE
	debug "Finished cleanup"
	exit
}

# function failed() 		# error handling with trap
#	usage: none really
#
function failed(){
	local r=$?
	set +o errtrace
	set +o xtrace
	$ECHO "An error occurred..."
	cleanup
}

# function usage()			# show the usage.dat file
#	usage: usage
#
function usage(){
	source usage.dat
}

# function mini_usage()		# show the mini_usage.dat file
#	usage: mini_usage
#
function mini_usage(){
	source mini_usage.dat
}

# function change_ifs()		# change the default field seperator
# 	usage: change_ifs ":"
# NOTE: this is an environment-wide change! so be sure to undo it at the end
# of the script. I only include it because i use it often. Dont use this.
function change_ifs(){
	new_ifs=$1
	OLDIFS="${IFS}"
	IFS=$new_ifs
	return
}

# function revert_ifs()		# revert the default field seperator
# 	usage: revert_ifs ":"
# NOTE: this is an environment-wide change! so be sure to undo it at the end
# of the script. I only include it because i use it often. Dont use this.
function revert_ifs(){
	IFS=$OLDIFS
	return
}

# function check_regex()	# look for a regex in a string, if match return true
#	usage: if $(check_regex $some_var $some_regex_pattern) then; echo "true"
#
function check_regex(){
	local input=$1
	local regex=$2
	if [[ $input =~ $regex ]]; then
		# echo "found some regex"
		return true
	else
		# echo "did not find some regex"
		return false
	fi
}

# function check_reqs()		# check that needed programs are installed
#	usage: none really (system)
#
function check_reqs(){
for x in "${REQUIRED_PROGS[@]}"
	do
		type "$x" >/dev/null 2>&1 || { $ECHO "$x is required and is NOT installed. Please install $x and try again. Exiting."; exit; }
	done
}

# function check_env()		# set tracing if dev or test environment
#	usage: none really (system)
#
function check_env(){
if [ $ENV != "prod" ] && [ $1 == "set" ]; then
	set -o errtrace 				# fail and exit on first error
	set -o xtrace					# show all output to console while writing script
fi
if [ $ENV != "prod" ] && [ $1 == "unset" ]; then
	set +o errtrace
	set +o xtrace
fi
}

# function only_run_as()	# only allow script to continue if uid matches
#	usage: only_run_as 0
#
function only_run_as(){
	if [[ $EUID -ne $1 ]]; then
		$ECHO "script must be run as uid $1" 1>&2
		exit
	fi
}

# function only_run_in()	# check that script is run from /root/bin
#	usage: only_run_in "/home/user"
#
function only_run_in(){
	local cwd=`pwd`
	if [ $cwd != "$1" ]; then
		$ECHO "script must be run from $1 directory";
		exit
	fi
}

# function only_run_for()	# Runs a command for a specified number of seconds
# usage: only_run_for [number of seconds] [command]
#
function only_run_for(){
 local runtime=${1:-1m}
 mypid=$$
 shift
 $@ &
 local cpid=$!
 sleep $runtime
 kill -s SIGTERM $cpid
}

# function text()			# output text ERROR or OK with color (good for cli output)
#	usage: text error "there was some sort of error"
#	usage: text ok "everything was ok"
#
function text(){
	local color=${1}
	shift
	local text="${@}"

	case ${color} in
		error  ) $ECHO -en "["; $TPUT setaf 1; $ECHO -en "ERROR"; $TPUT sgr0; $ECHO "] ${text}";;
		ok     ) $ECHO -en "["; $TPUT setaf 2; $ECHO -en "OK"; $TPUT sgr0; $ECHO "]    ${text}";;
	esac
	$TPUT sgr0
}
#
# END FUNCTIONS SECTION

# Make sure only root/whoever can run this script
# currently only uid 0 (root) is allowed to run this script
only_run_as 0

# does $LOGFILE exist, and is $LOGFILE writable?
[ -e $LOGFILE ] && debug "Logfile $LOGFILE exists" || debug "Logfile $LOGFILE does not exist, exiting.";
[ -w $LOGFILE ] && debug "Logfile $LOGFILE writeable" || debug "Logfile $LOGFILE no Writable, exiting.";

# echo shell vars to log file for debugging
if [ $DEBUG == "on" ]; then echo $VARS >> $LOGFILE; fi

# check for required program(s) listed in $REQUIRED_PROGS
check_reqs

# trap ERR into failed() function for handling
trap failed ERR

# trap EXIT and delete tmpfile, in case cleanup is not called
trap "/bin/rm -f ${TMPFILE}" EXIT 

# if environment is test or dev, then set bash tracing output to on.
check_env set

# modify usage.dat to suit the program 
# call usage or mini_usage to display a usage output and exit
# if args empty then display usage and exit
if [[ $# -lt $MINARGS ]]; then mini_usage; cleanup; fi

# argument handling - standard examples
while getopts ":dvV" opt; do
	case $opt in
		d)  
		$ECHO "-d debugging is on" 
		;;
		v)  
		$ECHO "-v verbosity is on" 
		;;
		V)  
		$ECHO "-V version info" 
		;;
		\?) 
		$ECHO "unknown arg: -$OPTARG" 
		;;
	esac
done

##################################

#
# additional scripting should go here
#

##################################

# echo all current vars to log file for debugging if debugging
# is enabled
NEW_VARS="`set -o posix ; set`"
if [ $DEBUG == "on" ]; then $ECHO $NEW_VARS >> $LOGFILE; fi

# clear bash traces if dev or test var was set
check_env unset

# call a clean exit
cleanup
