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

### BEGIN INIT INFO
# Provides:        LC_6
# Required-Start:  $local_fs $time
# Required-Stop:   $local_fs $time
# Default-Start:   2 3 4 5
# Default-Stop:    1
# Short-Description: Start LC_6 daemon
### END INIT INFO

# globals
	G_RETVAL=0
	G_DAEMON="/usr/local/bin/lc_6_agent"
	G_PID_FILE="/var/run/lc_6.pid"
	G_CONFIG_FILE="/etc/default/lc_6"

# ensure we are root
	if [ "$(id -u)" != "0" ]; then
		echo "FAIL: ${0} must be run as root" 1>&2
		G_RETVAL=1
		exit ${G_RETVAL}
	fi

# external shell references
	. /lib/lsb/init-functions

# ensure daemon installed
	test -x $G_DAEMON
	G_RETVAL=$?
	if [ $G_RETVAL -gt 0 ] ; then
		echo "FAIL: please install ${G_DAEMON} and try again, use lc_6_install.sh" 1>&2
		exit $G_RETVAL
	fi

# functions
usage ()
{
	echo "Usage: ${0} \ "
	echo "            start"
	echo "            stop"
	echo "            status"
	echo "            [--help|-?]"
}

# Check command line arguments
	if [ $# -eq 0 ] ; then
		usage
		exit 0
	fi

# main
	case "${1^^}" in
		START)
			log_daemon_msg "Starting LC_6 agent" "LC_6"
	  		start-stop-daemon --start --no-close --pidfile ${G_PID_FILE} --make-pidfile --background --exec ${G_DAEMON}
			G_RETVAL=$?
			log_end_msg $G_RETVAL
	  		;;
		STOP)
			log_daemon_msg "Stopping LC_6 agent" "LC_6"
	  		start-stop-daemon --stop --pidfile ${G_PID_FILE}
			G_RETVAL=$?
			log_end_msg $G_RETVAL
			if [ -f "${G_PID_FILE}" ] ; then
				rm -f "${G_PID_FILE}" &>/dev/null
			fi
	  		;;
		STATUS)
			status_of_proc ${G_DAEMON} "LC_6"
			;;
		--HELP|-?)
			usage
			exit 0
			;;
	  	*)
			usage
			echo "FAIL: Unknown action '${1}'" 1>&2
			G_RETVAL=1
			;;
	esac

# clean up 

exit ${G_RETVAL}
