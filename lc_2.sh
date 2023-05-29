#!/bin/bash
# ****************************************************************************
# * Description : Test 2 - file parsing and value arithmetic
# ****************************************************************************
# * Last commit details:
# * : 1 $
# * : lcowdrey $
# * : 2015-1101 15:59:58 +0100 (Sun, 1 November 2015) $
# * :  $
# ****************************************************************************

# globals
	G_RETVAL=0
	G_TARGET_ARCHIVE="script_log.tgz"
	G_TARGET_FILE="aspera.log"
	G_TEMP_FILE=$(mktemp)
	G_ASCP_LAST_ENTRY=0
	G_LONGEST_LAST=0
	G_LONGEST_PID=0
	G_BIGGEST_LAST=0
	G_BIGGEST_PID=0
	G_FASTEST_LAST=0
	G_FASTEST_PID=0

# arrays
  	# delete anything that may exist
  	if [ ${#ASCP_PID[@]} -gt 0 ] ; then
		unset ASCP_PID
		unset ASCP_UUID
		unset ASCP_INOUT
		unset ASCP_START
		unset ASCP_STOP
		unset ASCP_RATE
		unset ASCP_AMOUNT
		unset ASCP_SESSIONS
		unset ASCP_LOCAL
		unset ASCP_PEER
		unset ASCP_STATUS
		unset ASCP_PROG_T
		unset ASCP_PROG_F
		unset ASCP_PROG_E
  	else
      declare -a ASCP_PID
      declare -a ASCP_UUID
      declare -a ASCP_INOUT
      declare -a ASCP_START
      declare -a ASCP_STOP
      declare -a ASCP_RATE
      declare -a ASCP_AMOUNT
      declare -a ASCP_SESSIONS
      declare -a ASCP_LOCAL
      declare -a ASCP_PEER
      declare -a ASCP_STATUS
      declare -a ASCP_PROG_T
      declare -a ASCP_PROG_F
      declare -a ASCP_PROG_E
  	fi

#Total number of ascp  transfers;
#Listing of all transfers and their rate in Mb/s (Megabits per Second);
#PID of transfer(s) with the longest duration;
#PID of the transfer(s) sending the most data;
#PID of the transfer(s) with the fastest rate.
# t  (running total of bytes received) == 14604216
# f  (running total of file bytes received) == 14604216
# e  (total elapsed time [microseconds]) == 60189366

# functions

# start
	if [ -f "${G_TARGET_ARCHIVE}" ] ; then
		tar zxf "${G_TARGET_ARCHIVE}" &>/dev/null
		TAR_RETVAL=$?
		if [ "${TAR_RETVAL}" -eq 0 ] ; then
			if [ -f "${G_TARGET_FILE}" ] ; then
				LOG_LINE_PARSE=0
				while read LOG_LINE; do
					if [[ ${LOG_LINE} =~ ^.*FASP.Session.Start.*$ && ${LOG_LINE_PARSE} -eq 0 ]] ; then
						LOG_LINE_PARSE=1

#Jan 26 18:44:54 sldc1 ascp[1894]: LOG FASP Session Start uuid=09fe0c30-bf69-47d1-9db5-3bf60b8f1426 op=send status=started source=/data/to-sg-no-disk.sh (1) dest=/data userid=0 user="root" local=173.192.196.34:54338 peer=46.137.239.185:33001 targetrate=2000000000 minrate=0 transfer_policy=fair secure=no resume=2 precalc=yes tcp_mode=no rtt_autocorrect=yes cookie="aspera.console:b4eb5dea-0c3f-4e80-afb4-a03f83bbb0f8:Cloud-to-Cloud Global Distribution - Rerun 2" vlink_local=0 vlink_remote=0 vlink_sess_id=1543 os="Linux 2.6.32-431.3.1.el6.x86_64 #1 SMP F" ver=3.3.3.79205 lic=10:1:30811 peeros="Linux 2.6.32-358.14.1.el6.x86_64 #1 SMP " peerver=3.4.0.82480 peerlic=10:1:30812 proto_sess=20002 proto_udp=20000 proto_bwmeas=20000 proto_data=20007

						ASCP_PID+=($(echo -n "${LOG_LINE}"|sed "s@^.*ascp\[@@"|sed "s@\]:.*@@"))
						ASCP_UUID+=($(echo -n "${LOG_LINE}"|sed "s@^.*uuid=@@"|sed "s@ .*@@"))
						ASCP_INOUT+=($(echo -n "${LOG_LINE}"|sed "s@^.*uuid=.* op=@@"|sed "s@ .*@@"))
						ASCP_START+=($(date --date="${LOG_LINE:0:15}" +%s))
						ASCP_STOP+=($(date --date="${LOG_LINE:0:15}" +%s))
						ASCP_RATE+=(0)
						ASCP_AMOUNT+=(0)
						ASCP_STATUS+=("?")
						ASCP_LOCAL+=($(echo -n "${LOG_LINE}"|sed "s@^.*user=\".*\" local=@@"|sed "s@ .*@@"))
						ASCP_PEER+=($(echo -n "${LOG_LINE}"|sed "s@^.*user=\".*\" local=.* peer=@@"|sed "s@ .*@@"))
						ASCP_PROG_T+=(0)
						ASCP_PROG_F+=(0)
						ASCP_PROG_E+=(0)

					fi
					if [ ${LOG_LINE_PARSE} -eq 1 ] ; then
						if [[ ${LOG_LINE} =~ ^.*.prog.t/f/e=.*/.*/.*$  && ${LOG_LINE_PARSE} -eq 1 ]] ; then
							# keep updating last array value as log appears to show incremental progress
							ITEM_PROG_T=$(echo -n "${LOG_LINE}"|sed "s@^.*prog.t/f/e=@@"|sed "s@ .*@@"|cut -d"/" -f1)
							ITEM_PROG_F=$(echo -n "${LOG_LINE}"|sed "s@^.*prog.t/f/e=@@"|sed "s@ .*@@"|cut -d"/" -f2)
							ITEM_PROG_E=$(echo -n "${LOG_LINE}"|sed "s@^.*prog.t/f/e=@@"|sed "s@ .*@@"|cut -d"/" -f3)
							ASCP_PROG_T[$G_ASCP_LAST_ENTRY]=$(echo "${ASCP_PROG_T[$G_ASCP_LAST_ENTRY]}+(${ITEM_PROG_T:-0}/1024)"|bc) 
							ASCP_PROG_F[$G_ASCP_LAST_ENTRY]=$(echo "${ASCP_PROG_F[$G_ASCP_LAST_ENTRY]}+(${ITEM_PROG_F:-0}/1024)"|bc)
							ASCP_PROG_E[$G_ASCP_LAST_ENTRY]=$(echo "${ASCP_PROG_E[$G_ASCP_LAST_ENTRY]}+(${ITEM_PROG_E:-0}/1000000)"|bc)
							((ASCP_SESSIONS[$G_ASCP_LAST_ENTRY]+=1))
							ASCP_AMOUNT[$G_ASCP_LAST_ENTRY]=$(bc <<< "${ASCP_AMOUNT[$G_ASCP_LAST_ENTRY]}+${ITEM_PROG_T:-0}")
						fi

						if [[ ${LOG_LINE} =~ ^.*FASP.Transfer.Stop.*uuid=${ASCP_UUID[$G_ASCP_LAST_ENTRY]]}.*$ && ${LOG_LINE_PARSE} -eq 1 ]] ; then
							ITEM_RATE=$(echo -n "${LOG_LINE}"|sed "s@^.*rate=@@"|sed "s@ .*@@")
							# Kbps Mbps Gbps
							# Gbps to Mbps: ÷ 0.008
							if [[ $ITEM_RATE == *"Gbps"* ]] ; then
								ITEM_RATE=$(echo -n "${ITEM_RATE}"|sed "s@Gbps.*@@")
								ASCP_RATE[$G_ASCP_LAST_ENTRY]=$(bc <<< "scale=2; (${ITEM_RATE}/0.008)")
							elif [[ $ITEM_RATE == *"Kbps"* ]] ; then
								ITEM_RATE=$(echo -n "${ITEM_RATE}"|sed "s@Kbps.*@@")
								ASCP_RATE[$G_ASCP_LAST_ENTRY]=$(bc <<< "scale=2; (${ITEM_RATE}/1000)")
							elif [[ $ITEM_RATE == *"Mbps"* ]] ; then
								ASCP_RATE[$G_ASCP_LAST_ENTRY]=$(echo -n "${ITEM_RATE}"|sed "s@Mbps.*@@")
							fi
						fi

						if [[ ${LOG_LINE} =~ ^.*FASP.Session.Stop.*uuid=${ASCP_UUID[$G_ASCP_LAST_ENTRY]]}.*$ && ${LOG_LINE_PARSE} -eq 1 ]] ; then
							LOG_LINE_PARSE=0
							ASCP_STOP[$G_ASCP_LAST_ENTRY]=$(date --date="${LOG_LINE:0:15}" +%s)
							ASCP_STATUS[$G_ASCP_LAST_ENTRY]=$(echo -n "${LOG_LINE}"|sed "s@^.*op=.* status=@@"|sed "s@ .*@@")

							((G_ASCP_LAST_ENTRY += 1))
						fi
					fi
				done < "${G_TARGET_FILE}"

				echo "INFO: total transfers=$(printf "%'.f" ${#ASCP_PID[@]})"
				# cycle through and determine, longest, sent most, fastest
				if [ ${#ASCP_PID[@]} -gt 0 ] ; then
					for ASCP_IDX in ${!ASCP_PID[*]} ; do
						# fastest
						if [ $(echo "${ASCP_RATE[$ASCP_IDX]}>${G_FASTEST_LAST}"|bc -l) -eq 1 ] ; then
							G_FASTEST_LAST=${ASCP_RATE[$ASCP_IDX]}
							G_FASTEST_PID=${ASCP_PID[$ASCP_IDX]}
						fi
						# longest
						G_DURATION_TMP=$(bc <<< "(${ASCP_STOP[$ASCP_IDX]}-${ASCP_START[$ASCP_IDX]})")
						if [ $(echo "${G_DURATION_TMP}>${G_LONGEST_LAST}"|bc -l) -eq 1 ] ; then
							G_LONGEST_LAST=${G_DURATION_TMP}
							G_LONGEST_PID=${ASCP_PID[$ASCP_IDX]}
						fi
						# most sent
						if [ $(echo "${ASCP_PROG_T[$ASCP_IDX]}>${G_BIGGEST_LAST}"|bc -l) -eq 1 ] ; then
							G_BIGGEST_LAST=${ASCP_PROG_T[$ASCP_IDX]}
							G_BIGGEST_PID=${ASCP_PID[$ASCP_IDX]}
						fi
					done
					echo "INFO: fastest transfer PID=${G_FASTEST_PID}, rate=${G_FASTEST_LAST}Mb/s"
					echo "INFO: longest transfer PID=${G_LONGEST_PID}, seconds=${G_LONGEST_LAST}"
					echo "INFO: biggest transfer PID=${G_BIGGEST_PID}, bytes=${G_BIGGEST_LAST}"
				fi

				# transfer summary
				if [ ${#ASCP_PID[@]} -gt 0 ] ; then
					ASCP_TOTAL_TRANSFERS=${#ASCP_PID[@]}
					ASCP_TOTAL_IDX=0
					for ASCP_IDX in ${!ASCP_PID[*]} ; do
						ASCP_TOTAL_IDX=$((ASCP_TOTAL_IDX+1))
						echo "INFO: transfer=${ASCP_TOTAL_IDX} PID=${ASCP_PID[$ASCP_IDX]} from=${ASCP_LOCAL[$ASCP_IDX]} to=${ASCP_PEER[$ASCP_IDX]} bytes=${ASCP_PROG_T[$ASCP_IDX]} status=${ASCP_STATUS[$ASCP_IDX]} rate=${ASCP_RATE[$ASCP_IDX]}Mb/s sessions=${ASCP_SESSIONS[$ASCP_IDX]} amount=${ASCP_AMOUNT[$ASCP_IDX]}"
					done
				fi

				G_RETVAL=0

				# clean up unpacked files
				if [ -f "${G_TARGET_FILE}" ] ; then
					rm -f "${G_TARGET_FILE}" &>/dev/null
				fi
			else
				echo "FAIL: ${G_TARGET_FILE} not found within ${G_TARGET_ARCHIVE}"
				G_RETVAL=1
			fi
		else
			echo "FAIL: unable to unpack ${G_TARGET_ARCHIVE}"
			G_RETVAL=1
		fi
	else
		echo "FAIL: ${G_TARGET_ARCHIVE} not found"
		G_RETVAL=1
	fi

# clean up 
	if [ -f "${G_TEMP_FILE}" ] ; then
		rm -f "${G_TEMP_FILE}" &>/dev/null
	fi

  	if [ ${#ASCP_PID[@]} -gt 0 ] ; then
		unset ASCP_PID
		unset ASCP_UUID
		unset ASCP_INOUT
		unset ASCP_START
		unset ASCP_STOP
		unset ASCP_RATE
		unset ASCP_AMOUNT
		unset ASCP_SESSIONS
		unset ASCP_LOCAL
		unset ASCP_PEER
		unset ASCP_STATUS
		unset ASCP_PROG_T
		unset ASCP_PROG_F
		unset ASCP_PROG_E
	fi

exit ${G_RETVAL}