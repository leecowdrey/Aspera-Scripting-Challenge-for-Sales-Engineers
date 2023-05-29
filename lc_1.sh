#!/bin/bash
# ****************************************************************************
# * Description : Test 1 - JSON retrieve and extract
# ****************************************************************************
# * Last commit details:
# * : 1 $
# * : lcowdrey $
# * : 2015-1101 15:59:58 +0100 (Sun, 1 November 2015) $
# * :  $
# ****************************************************************************

# globals
	G_RETVAL=0
	G_USE_JQ=0
	G_USE_CURL=0
	G_USE_WGET=0
	G_TARGET_URL="http://date.jsontest.com/"
	G_OVER_QUOTA_MESSAGE="<H1>Over Quota</H1>"
	G_TEMP_FILE=$(mktemp)
	G_EPOCH_LOCAL=0
	G_EPOCH_REMOTE=0
	G_EPOCH_DELTA=0
	G_EPOCH_DELTA_SECONDS=0
	G_HEADER_ACCEPT_VALUE="application/json"

# functions
usage ()
{
	echo "Usage: ${0} \ "
	echo "            [--url|-u {Test URL}]"
	echo "            [--mime-format|-f {JSON|TEXT|...}]"
	echo "            [--help|-?]"
}

# check if helper tools available
# is JQ installed?
	command -v /usr/bin/jq &>/dev/null
	if [ "${?}" -eq 0 ] ; then
		G_USE_JQ=1
	else
		echo "INFO: jq (Command-line JSON processor) not available, using built-ins"
		G_USE_JQ=0
	fi
# is curl installed?
	command -v /usr/bin/curl &>/dev/null
	if [ "${?}" -eq 0 ] ; then
		G_USE_CURL=1
	else
		echo "FAIL: curl must be installed, please install curl and try again"
		G_RETVAL=1
		exit ${G_RETVAL}
	fi

# Check command line arguments for overrides
	OPTION="${1}"
	while [ $# -gt 0 ] ; do
		case "${OPTION}" in
			--url|-u)
				shift
				G_TARGET_URL="${1,,}"
				;;
			--mime-format|-f)
				shift
				G_HEADER_ACCEPT_VALUE="application/${1,,}"
				;;
			--help|-?)
				usage
				exit 0
				;;
			*)
				usage
				echo "Invalid argument '${OPTION}'"
				exit 0
				;;
		esac
		shift
		OPTION=$1
	done

# start
	echo "INFO: requesting ${G_TARGET_URL} (mime-type: ${G_HEADER_ACCEPT_VALUE})"
	G_EPOCH_LOCAL=$(date +%s%3N) && /usr/bin/curl -H "Accept: ${G_HEADER_ACCEPT_VALUE}" -X GET ${G_TARGET_URL} &>${G_TEMP_FILE}
	G_RETVAL=$?

	if [ -f "${G_TEMP_FILE}" ] ; then
		OVER_QUOTA=$(grep -i "${G_OVER_QUOTA_MESSAGE}" ${G_TEMP_FILE}|wc -l)
		# jsontest.com reporting over quota on Google Compute Cloud, so if detected use sample file instead
		if [ ${OVER_QUOTA} -gt 0 ] ; then
			echo "INFO: ${G_TARGET_URL} reporting over quota, using sample JSON file instead"
			cat > "${G_TEMP_FILE}" <<EOF
{
  "time": "03:53:25 AM",
  "milliseconds_since_epoch": 1362196405309,
  "date": "03-02-2013"
}
EOF
		fi

		if [ "${G_RETVAL}" -eq 0 ] ; then
			if [ ${G_USE_JQ} -eq 0 ] ; then
				G_EPOCH_REMOTE=$(cat "${G_TEMP_FILE}"|/usr/bin/jq '.milliseconds_since_epoch')
			else
				G_EPOCH_REMOTE=$(grep -i "\"milliseconds_since_epoch\":" "${G_TEMP_FILE}"|cut -d":" -f2|cut -d"," -f1|tr -d "[[:space:]]")
			fi
			if [ -n "${G_EPOCH_REMOTE}" ] ; then
				G_EPOCH_DELTA=$((${G_EPOCH_REMOTE}-${G_EPOCH_LOCAL}))
				G_EPOCH_DELTA_SECONDS=$(bc <<< "scale=3; (${G_EPOCH_DELTA}/1000.0)")
				echo "INFO: Local=${G_EPOCH_LOCAL}"
				echo "INFO: Remote=${G_EPOCH_REMOTE}"
				echo "INFO: Difference=${G_EPOCH_DELTA_SECONDS} seconds [${G_EPOCH_DELTA} milliseconds]"
				G_RETVAL=0
			else
				echo "FAIL: remote EPOCH value not found"
				G_RETVAL=1
			fi
		else
			echo "FAIL: ${G_TARGET_URL} not reachable"
			G_RETVAL=1
		fi
		G_RETVAL=1
	else
		echo "FAIL: No file received from ${G_TARGET_URL}"
		G_RETVAL=1
	fi

	
# clean up 
	if [ -f "${G_TEMP_FILE}" ] ; then
		rm -f "${G_TEMP_FILE}" &>/dev/null
	fi

exit ${G_RETVAL}