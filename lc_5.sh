#!/bin/bash
# ****************************************************************************
# * Description : Test 5 - install SSH publickey on remote server
# ****************************************************************************
# * Last commit details:
# * : 1 $
# * : lcowdrey $
# * : 2015-1101 15:59:58 +0100 (Sun, 1 November 2015) $
# * :  $
# ****************************************************************************

# globals
	G_RETVAL=0
	G_REMOTE_USER=$(whoami)
	G_REMOTE_HOST=""
	G_REMOTE_PORT=22
	G_REMOTE_PASSWORD=""
	G_REMOTE_PASSWORD_FILE=""
	G_REMOTE_PASSWORD_ENV=""
	G_PUBLIC_KEY_FILE=""
	G_SSHPASS_OPTIONS=""

# functions
usage ()
{
	echo "Usage: ${0} \ "
	echo "            --host|-h {hostname or IPv4/IPv6 address}"
	echo "            --public-key-file|-f {filename}"
	echo "            [--port|-p {port-number}]          # default: ${G_REMOTE_PORT} "
	echo "            [--username|-u {username}]         # default: ${G_REMOTE_USER}"
	echo "            [--password|-p {password}]"
	echo "            [--password-env|-pe {env-name}]    # set in parent shell using: export env-name=\"value\""
	echo "            [--password-file|-pf {filename}]"
	echo "            [--help|-?]"
}

# Check command line arguments
	if [ $# -eq 0 ] ; then
		usage
		exit 0
	fi

	OPTION="${1}"
	while [ $# -gt 0 ] ; do
		case "${OPTION}" in
			--host|-h)
				shift
				G_REMOTE_HOST="$1"
				;;
			--public-key-file|-f)
				shift
				G_PUBLIC_KEY_FILE="$1"
				;;
			--username|-u)
				shift
				G_REMOTE_USER="$1"
				;;
			--password|-p)
				shift
				G_REMOTE_PASSWORD="$1"
				;;
			--password-env|-pe)
				shift
				G_REMOTE_PASSWORD_ENV="$1"
				;;
			--password-file|-pf)
				shift
				G_REMOTE_PASSWORD_FILE="$1"
				;;
			--port|-p)
				shift
				G_REMOTE_PORT=$1
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

# check if helper tools available
# is sshpass installed?
	command -v /usr/bin/sshpass &>/dev/null
	if [ "${?}" -ne 0 ] ; then
		echo "FAIL: sshpass not installed, please install sshpass and try again"
		G_RETVAL=1
		exit ${G_RETVAL}
	fi
	command -v /usr/bin/ssh-keyscan &>/dev/null
	if [ "${?}" -ne 0 ] ; then
		echo "FAIL: ssh-keyscan not installed, please install openssh-client and try again"
		G_RETVAL=1
		exit ${G_RETVAL}
	fi
	command -v /usr/bin/ssh-copy-id &>/dev/null
	if [ "${?}" -ne 0 ] ; then
		echo "FAIL: ssh-copy-id not installed, please install openssh-client and try again"
		G_RETVAL=1
		exit ${G_RETVAL}
	fi
	command -v /usr/bin/ssh-keygen &>/dev/null
	if [ "${?}" -ne 0 ] ; then
		echo "FAIL: ssh-keygen not installed, please install openssh-client and try again"
		G_RETVAL=1
		exit ${G_RETVAL}
	fi

# check we have enough values and the ones that were supplied were valid
	if [ -z "${G_REMOTE_PORT}" ] ; then
		echo "FAIL: no remote SSH port number supplied"
		G_RETVAL=1
	else
		if [[ "${G_REMOTE_PORT}" -lt 1 || "${G_REMOTE_PORT}" -gt 65535 ]] ; then
			echo "FAIL: remote SSH port number ${G_REMOTE_PORT} was out of range (1..65535)"
			G_RETVAL=1
		fi
	fi
	if [ -z "${G_REMOTE_HOST}" ] ; then
		echo "FAIL: no remote host suppplied"
		G_RETVAL=1
	fi
	if [[ -z "${G_REMOTE_PASSWORD}" && -z "${G_REMOTE_PASSWORD_FILE}" && -z "${G_REMOTE_PASSWORD_ENV}" ]] ; then
		echo "FAIL: no password option supplied"
		echo -n "Please enter password: "
		read -s G_REMOTE_PASSWORD
		if [ -z "${G_REMOTE_PASSWORD}" ] ; then
			G_RETVAL=1
		fi
	fi
	if [ -n "${G_REMOTE_PASSWORD}" ] ; then
		export SSHPASS="${G_REMOTE_PASSWORD}"
		G_SSHPASS_OPTIONS="-e"
	fi
	if [ -n "${G_REMOTE_PASSWORD_FILE}" ] ; then
		if [ -f "${G_REMOTE_PASSWORD_FILE}" ] ; then
			G_SSHPASS_OPTIONS="-f ${G_REMOTE_PASSWORD_FILE}"
		else
			echo "FAIL: password file ${G_REMOTE_PASSWORD_FILE} was not found"
			G_RETVAL=1
		fi
	fi
	if [ -n "${G_REMOTE_PASSWORD_ENV}" ] ; then
		G_REMOTE_PASSWORD=${!G_REMOTE_PASSWORD_ENV}
		if [ -z "${G_REMOTE_PASSWORD}" ] ; then
			echo "FAIL: password environment variable ${G_REMOTE_PASSWORD_ENV} was empty"
			G_RETVAL=1
		else
			export SSHPASS="${G_REMOTE_PASSWORD}"
			G_SSHPASS_OPTIONS="-e"
		fi
	fi

	if [ -n "${G_PUBLIC_KEY_FILE}" ] ; then
		if [ -f "${G_PUBLIC_KEY_FILE}" ] ; then
			SSH_KEY_VALID=$(ssh-keygen -l -f "${G_PUBLIC_KEY_FILE}" &>/dev/null)
			if [ $? -gt 0 ] ; then
				echo "FAIL: public key file ${G_PUBLIC_KEY_FILE} is invalid"
				G_RETVAL=1
			else
				echo "INFO: public key file ${G_PUBLIC_KEY_FILE} is valid"
			fi
		else
			echo "FAIL: public key file ${G_PUBLIC_KEY_FILE} was not found"
			G_RETVAL=1
		fi
	fi

	if [ ${G_RETVAL} -ne 0 ] ; then
		exit ${G_RETVAL}
	fi

# start

	# remove existing host fingerprint in case has changed through many redeploys
	if [ -f ~/.ssh/known_hosts ] ; then
		/usr/bin/ssh-keygen -f ~/.ssh/known_hosts -R ${G_REMOTE_HOST} &>/dev/null
	fi

	# find IP address (IPv4 or IPv6) of specified host, if already address then address is returned
	G_REMOTE_HOST_IP=$(getent hosts ${G_REMOTE_HOST,,}|awk '{ print $1 }')
	# check IPv4 regex incase need to use ping6
	if [[ ${G_REMOTE_HOST_IP} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] ; then
		/bin/ping -c 1 -n -q ${G_REMOTE_HOST_IP} &>/dev/null
	else
		/bin/ping6 -c 1 -n -q ${G_REMOTE_HOST_IP} &>/dev/null
	fi
	G_RETVAL=$?
	if [ ${G_RETVAL} -gt 0 ] ; then
		echo "FAIL: remote host ${G_REMOTE_HOST,,} not available or reachable via ping"
		G_RETVAL=1
		exit ${G_RETVAL}
	else
		echo "INFO: remote host ${G_REMOTE_HOST,,} responding via ping"
	fi

	# check host is responding via SSH if ping was successful
	/usr/bin/ssh-keyscan -T 15 -H -p ${G_REMOTE_PORT} ${G_REMOTE_HOST,,} &>/dev/null
	G_RETVAL=$?
	if [ ${G_RETVAL} -eq 0 ] ; then
		echo "INFO: remote host ${G_REMOTE_HOST,,}:${G_REMOTE_PORT} responding via SSH subsystem"
		G_RETVAL=0
	else
		echo "FAIL: remote host ${G_REMOTE_HOST,,}:${G_REMOTE_PORT} failed to respond via SSH subsystem"
		G_RETVAL=1
		exit ${G_RETVAL}
	fi

	# host responding to both ping and ssh-keyscan so now attempt ssh-copy-id
	/usr/bin/sshpass ${G_SSHPASS_OPTIONS} /usr/bin/ssh-copy-id -o StrictHostKeyChecking=no -p ${G_REMOTE_PORT} ${G_REMOTE_USER}@${G_REMOTE_HOST,,} &>/dev/null
	G_RETVAL=$?
	if [ ${G_RETVAL} -eq 0 ] ; then
		echo "OK: public key ${G_PUBLIC_KEY_FILE} uploaded to ${G_REMOTE_USER}@${G_REMOTE_HOST,,}:${G_REMOTE_PORT}"
	else
		echo "FAIL: public key ${G_PUBLIC_KEY_FILE} could not be uploaded to ${G_REMOTE_USER}@${G_REMOTE_HOST,,}:${G_REMOTE_PORT}"
	fi

# clean up 
	if [ -n "${SSHPASS}" ] ; then
		unset SSHPASS
	fi

exit ${G_RETVAL}