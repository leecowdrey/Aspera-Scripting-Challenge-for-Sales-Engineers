#!/bin/bash
# ****************************************************************************
# * Description : Test 6 - install helper
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
		sudo ./lc_6_uninstall.sh
	fi
	sudo cp -f -v lc_6.sh /etc/init.d/lc_6
	sudo cp -f -v lc_6_agent.sh /usr/local/bin/lc_6_agent
	sudo cp -f -v lc_6.cfg /etc/default/lc_6
	sudo chmod 755 /etc/init.d/lc_6 /usr/local/bin/lc_6_agent
	sudo chown root:root /etc/init.d/lc_6 /usr/local/bin/lc_6_agent
	sudo chmod 640 /etc/default/lc_6
	sudo chown root:root /etc/default/lc_6
	#
	if [ "${OS_SYSTEMCTL_DEFAULT}" -eq 1 ] ; then 
		sudo systemctl daemon-reload
	fi
	#
	sudo update-rc.d lc_6 defaults
	sudo update-rc.d lc_6 enable
else
	echo "OS not supported, please try Debian derivative like Ubuntu"
fi