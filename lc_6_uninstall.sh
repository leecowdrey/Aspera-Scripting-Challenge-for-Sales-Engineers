#!/bin/bash
# ****************************************************************************
# * Description : Test 6 - uninstall helper
# ****************************************************************************
# * Last commit details:
# * : 1 $
# * : lcowdrey $
# * : 2015-1101 15:59:58 +0100 (Sun, 1 November 2015) $
# * :  $
# ****************************************************************************
if [ -f /etc/debian_version ] ; then
	OS_VERSION=$(lsb_release -a|grep "Release:"|cut -d":" -f2|tr -d '[:blank:]')
	OS_SYSTEMCTL_DEFAULT=$(echo "${OS_VERSION}>=15.04"|bc -l)

	if [[ -f /usr/local/bin/lc_6_agent || -f /etc/init.d/lc_6 || -f /etc/default/lc_6 ]] ; then
		sudo update-rc.d lc_6 disable &>/dev/null 
		sudo update-rc.d -f lc_6 remove &>/dev/null 
		rm -f /usr/local/bin/lc_6_agent /etc/init.d/lc_6 /etc/default/lc_6 &>/dev/null 
		if [ "${OS_SYSTEMCTL_DEFAULT}" -eq 1 ] ; then 
			sudo systemctl daemon-reload &>/dev/null 
		fi
	fi
else
	echo "OS not supported, please try Debian derivative like Ubuntu"
fi