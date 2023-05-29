#!/bin/bash
# ****************************************************************************
# * Description : Test 6 - detached process to monitor and predict storage
# ****************************************************************************
# * Last commit details:
# * : 1 $
# * : lcowdrey $
# * : 2015-1101 15:59:58 +0100 (Sun, 1 November 2015) $
# * :  $
# ****************************************************************************

# globals (defaults)
	G_RETVAL=0
	G_FOLDER="/tmp"
	G_INTERVAL=1
	G_SLEEP_INTERVAL=60
	G_LOG_FILE=""
	G_CONFIG_FILE="/etc/default/lc_6"
	G_USAGE_EPOCH=0
	G_USAGE_BYTES=0
	G_AVAILABLE_BYTES=0
	G_PREVIOUS_USAGE_EPOCH=0
	G_PREVIOUS_USAGE_BYTES=0
	G_DIFF_SECONDS=0
	G_DIFF_BYTES=0
	G_DIFF_PERCENT=0
	G_MODE_SERVICE=1
	G_PUSH_BACKGROUND=0

# functions
display_env ()
{
	echo "INFO: monitor folder=${G_FOLDER}"
	echo "INFO: log file=${G_LOG_FILE}"
	echo "INFO: interval=${G_INTERVAL} [${G_SLEEP_INTERVAL} seconds]"
}

load_env ()
{
	# read parameters from config file
	if [ ! -f "${G_CONFIG_FILE}" ] ; then
		echo "FAIL: parameter file ${G_CONFIG_FILE} is missing, aborting"
		G_RETVAL=1
		exit ${G_RETVAL}
	fi

	G_FOLDER=$(grep -e "^G_FOLDER=" ${G_CONFIG_FILE}|cut -d"=" -f2)
	G_LOG_FILE=$(grep -e "^G_LOG_FILE=" ${G_CONFIG_FILE}|cut -d"=" -f2)
	G_INTERVAL=$(grep -e "^G_INTERVAL=" ${G_CONFIG_FILE}|cut -d"=" -f2)

	if [ ${G_INTERVAL} -lt 1 ] ; then
		G_INTERVAL=1
	elif [ ${G_INTERVAL} -gt 1440 ] ; then
		G_INTERVAL=1440
	fi
	G_SLEEP_INTERVAL=$(bc <<< "(${G_INTERVAL}*60)")
	display_env
}

# check for service vs user execution
	if [ $# -eq 0 ] ; then
		G_MODE_SERVICE=1
	else
		G_MODE_SERVICE=0
		OPTION="${1}"
		while [ $# -gt 0 ] ; do
			case "${OPTION}" in
				--folder|-f)
					shift
					G_FOLDER="$1"
					;;
				--log-file|-l)
					shift
					G_LOG_FILE="$1"
					;;
				--interval|-i)
					shift
					G_INTERVAL=$(echo -n "${1}"|cut -d"." -f1|cut -d"-" -f2)
					if [ "${G_INTERVAL}" -lt 1 ] ; then
						G_INTERVAL=1
					elif [ "${G_INTERVAL}" -gt 1440 ] ; then
						G_INTERVAL=1440
					fi
					G_SLEEP_INTERVAL=$(bc <<< "(${G_INTERVAL}*60)")
					;;
				--background|-bg)
					G_PUSH_BACKGROUND=1
					;;
				*)
					;;
			esac
			shift
			OPTION=$1
		done
	fi

# move to background?
	if [ ${G_PUSH_BACKGROUND} -eq 1 ] ; then
		G_LOG_FILE="${G_LOG_FILE:-$(mktemp)}"
		display_env
		nohup ${0} --folder ${G_FOLDER} --interval ${G_INTERVAL} --log-file ${G_LOG_FILE} &>>${G_LOG_FILE} &
		G_PID=$!
		G_RETVAL=$?
		echo "INFO: agent spawned to background, ${G_PID}"
		exit ${G_RETVAL}
	fi

# main

	if [ -z "${G_LOG_FILE}" ] ; then
		G_LOG_FILE=$(mktemp)
	fi

	if [ ${G_MODE_SERVICE} -eq 1 ] ; then
		echo "INFO: agent starting"
		load_env
		display_env
	else
		display_env
	fi
	declare -t LC_6_AGENT_RUN=0
	trap -- 'LC_6_AGENT_RUN=1;' SIGABRT SIGTERM
	trap -- 'LC_6_AGENT_RUN=2;' SIGTRAP
	while [ ${LC_6_AGENT_RUN} -ne 1 ] ; do
		G_PREVIOUS_USAGE_EPOCH=${G_USAGE_EPOCH}
		G_PREVIOUS_USAGE_BYTES=${G_USAGE_BYTES}
		G_AVAILABLE_BYTES=$(bc <<< $(stat -f --format="%a*%S" ${G_FOLDER}))
		G_USAGE_EPOCH=$(date +%s)
		G_USAGE_BYTES=$(du -b -s "${G_FOLDER}"|awk '{ print $1 }')
		G_DIFF_EPOCH=$(bc <<< "scale=3; (${G_USAGE_EPOCH}-${G_PREVIOUS_USAGE_EPOCH})")
		G_DIFF_BYTES=$(bc <<< "(${G_USAGE_BYTES}-${G_PREVIOUS_USAGE_BYTES})")
		if [[ ${G_DIFF_BYTES} -gt 0 && ${G_PREVIOUS_USAGE_BYTES} -gt 0 ]] ; then
			G_DIFF_PERCENT=$(bc <<< "scale=2;(((${G_USAGE_BYTES}-${G_PREVIOUS_USAGE_BYTES})/${G_USAGE_BYTES})*100)")
			G_SLOTS_REMAINING=$(bc <<< "(${G_AVAILABLE_BYTES}/${G_DIFF_BYTES})")
			G_LIFE_TICKS=$(bc <<< "scale=3; (${G_SLOTS_REMAINING}*${G_DIFF_EPOCH})")
			G_TICKS_REMAINING=$(bc <<< "(${G_USAGE_EPOCH}+${G_LIFE_TICKS})")
		else
			G_DIFF_PERCENT=0
			G_TICKS_REMAINING=2147483647
		fi
		G_EXPIRATION=$(date -d @${G_TICKS_REMAINING} +"%a %b %d %H:%m:%S %Z %Y")

		#echo "${G_FOLDER}|${G_USAGE_EPOCH}|${G_DIFF_EPOCH}|${G_AVAILABLE_BYTES}|${G_USAGE_BYTES}|${G_DIFF_BYTES}|${G_DIFF_PERCENT}%|${G_TICKS_REMAINING}|${G_EXPIRATION}"
		if [ ${G_MODE_SERVICE} -eq 1 ] ; then
			echo "INFO: folder ${G_FOLDER} change=${G_DIFF_PERCENT}%, expiration=${G_EXPIRATION}" |tee -a "${G_LOG_FILE}"
		else
			echo "INFO: folder ${G_FOLDER} change=${G_DIFF_PERCENT}%, expiration=${G_EXPIRATION}"
		fi

		if [ ${LC_6_AGENT_RUN} -eq 2 ] ; then
			LC_6_AGENT_RUN=0
			if [ ${G_MODE_SERVICE} -eq 1 ] ; then
				load_env
				display_env
			fi
		fi
		sleep ${G_SLEEP_INTERVAL}
	done
	if [ ${G_MODE_SERVICE} -eq 1 ] ; then
		echo "INFO: agent stopping"
	fi

# clean up 

exit ${G_RETVAL}