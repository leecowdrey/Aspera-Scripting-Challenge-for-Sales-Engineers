#!/bin/bash
# ****************************************************************************
# * Description : Test 3 - local cp without cp
# ****************************************************************************
# * Last commit details:
# * : 1 $
# * : lcowdrey $
# * : 2015-1101 15:59:58 +0100 (Sun, 1 November 2015) $
# * :  $
# ****************************************************************************

# globals
	G_RETVAL=0
	G_FILENAME_SRC=""
	G_FILENAME_DST=""
	G_DST_DIRNAME=""
	G_DST_BASENAME=""
	G_MAKE_DST_PATHS=0
	G_PRESERVE_PERMISSIONS=0
	G_PRESERVE_UIDGID=0
	G_PRESERVE_TIMESTAMPS=0
	G_OVERWRITE_DST=0
	G_STATISTICS=0
	G_USE_CAT=1
	G_USE_RSYNC=0
	G_RSYNC_PARAM="--archive --no-compress --no-checksum --ignore-errors --quiet"
	G_FILE_COPIED=0

# functions
usage ()
{
	echo "Usage: ${0} \ "
	echo "            --source|-s {filename}"
	echo "            --destination|-d {filename}"
	echo "            [--make-paths|-m]"
	echo "            [--overwrite|-o]"
	echo "            [--preserve-permissions|-pp]"
	echo "            [--preserve-owner|-po]"
	echo "            [--preserve-timestamps|-pt]"
	echo "            [--statistics|-s]"
	echo "            [--cat|-c]   # default"
	echo "            [--rsync|-r]"
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
			--source|-s)
				shift
				G_FILENAME_SRC="$1"
				;;
			--destination|-d)
				shift
				G_FILENAME_DST="$1"
				;;
			--make-paths|-m)
				G_MAKE_DST_PATHS=1
				;;
			--overwrite|-o)
				G_OVERWRITE_DST=1
				;;
			--preserve-permissions|-pp)
				G_PRESERVE_PERMISSIONS=1
				;;
			--preserve-owner|-po)
				G_PRESERVE_UIDGID=1
				;;
			--preserve-timestamps|-pt)
				G_PRESERVE_TIMESTAMPS=1
				;;
			--statistics|-s)
				G_STATISTICS=1
				;;
			--cat|-c)
				G_USE_CAT=1
				G_USE_RSYNC=0
				;;
			--rsync|-r)
				G_USE_RSYNC=1
				G_USE_CAT=0
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
# is RSYNC installed, if selected but not available force method to CAT?
	if [ ${G_USE_RSYNC} -eq 1 ] ; then
		command -v /usr/bin/rsync &>/dev/null
		if [ "${?}" -ne 0 ] ; then
			G_USE_RSYNC=0
			G_USE_CAT=1
			echo "INFO: rsync not available, using cat"
		fi
	fi

# start
	if [ -n "${G_FILENAME_SRC}" ] && [ -n "${G_FILENAME_DST}" ] ; then
		if [ -f "${G_FILENAME_SRC}" ] ; then
			G_DST_DIRNAME=$(dirname "${G_FILENAME_DST}")
			G_DST_BASENAME=$(basename "${G_FILENAME_DST}")
			if [ -z "${G_DST_DIRNAME}" ] ; then
				G_DST_DIRNAME="."
			fi
			if [ -z "${G_DST_BASENAME}" ] ; then
				G_DST_BASENAME=$(basename "${G_FILENAME_SRC}")
			fi
			if [ -n "${G_DST_DIRNAME}" ] && [ -n "${G_DST_BASENAME}" ] ; then
				if [ ! -d "${G_DST_DIRNAME}" ] ; then
					if [ ${G_MAKE_DST_PATHS} -eq 1 ] ; then
						mkdir -p "${G_DST_DIRNAME}" &>/dev/null
					else
						echo "FAIL: destination directory not found, try again with --make-paths if necessary"
						G_RETVAL=1
					fi
				fi
				if [ -f "${G_DST_DIRNAME}/${G_DST_BASENAME}" ] ; then
					if [ ${G_OVERWRITE_DST} -eq 1 ] ; then
						rm -f "${G_DST_DIRNAME}/${G_DST_BASENAME}" &>/dev/null
					else
						echo "FAIL: destination file already exists, try again with --overwrite if necessary"
						G_RETVAL=1
					fi
				fi
				# proceed if no previous error state
				if [ ${G_RETVAL} -eq 0 ] ; then
					if [ ${G_USE_CAT} -eq 1 ] ; then
						# included G_STATISTICS if selected
						if [ ${G_STATISTICS} -eq 1 ] ; then
							time /bin/cat "${G_FILENAME_SRC}" > "${G_DST_DIRNAME}/${G_DST_BASENAME}"
						else
							/bin/cat "${G_FILENAME_SRC}" > "${G_DST_DIRNAME}/${G_DST_BASENAME}"
						fi
						G_FILE_COPIED=$?
						if [ ${G_FILE_COPIED} -eq 0 ] && [ -f "${G_DST_DIRNAME}/${G_DST_BASENAME}" ] ; then
							# preserve file permissions on destination
							if [ ${G_PRESERVE_PERMISSIONS} -eq 1 ] ; then
								UMASK_SRC=$(stat -c "%a" "${G_FILENAME_SRC}")
								#echo "INFO: setting file permissions mask ${UMASK_SRC}"
								chmod ${UMASK_SRC} "${G_DST_DIRNAME}/${G_DST_BASENAME}"
							fi
							# preserve file owner:group on destination
							if [ ${G_PRESERVE_UIDGID} -eq 1 ] ; then
								UIDGID_SRC=$(stat -c "%u:%g" "${G_FILENAME_SRC}")
								#echo "INFO: setting file owner:group ${UIDGID_SRC}"
								chown ${UIDGID_SRC} "${G_DST_DIRNAME}/${G_DST_BASENAME}"
							fi
							# preserve file timestamps on destination
							if [ ${G_PRESERVE_TIMESTAMPS} -eq 1 ] ; then
								TIMESTAMP_SRC=$(date -r "${G_FILENAME_SRC}")
								#echo "INFO: setting file timestamps ${TIMESTAMP_SRC}"
								/usr/bin/touch -d "${TIMESTAMP_SRC}" "${G_DST_DIRNAME}/${G_DST_BASENAME}"
							fi
							G_RETVAL=0
							echo "OK: ${G_FILENAME_SRC} copied to ${G_DST_DIRNAME}/${G_DST_BASENAME}"
						else
							G_RETVAL=1
							echo "FAIL: ${G_FILENAME_SRC} not copied to ${G_DST_DIRNAME}/${G_DST_BASENAME}"
						fi
					fi
					if [ ${G_USE_RSYNC} -eq 1 ] ; then
						# build up parameters for rsync
						# preserve file permissions on destination
						if [ ${G_PRESERVE_PERMISSIONS} -eq 1 ] ; then
							G_RSYNC_PARAM="${G_RSYNC_PARAM} --perms --executability"
						fi
						# preserve file owner:group on destination
						if [ ${G_PRESERVE_UIDGID} -eq 1 ] ; then
							G_RSYNC_PARAM="${G_RSYNC_PARAM} --owner --group"
						fi
						# preserve file timestamps on destination
						if [ ${G_PRESERVE_TIMESTAMPS} -eq 1 ] ; then
							G_RSYNC_PARAM="${G_RSYNC_PARAM} --times"
						fi
						# included G_STATISTICS if selected
						if [ ${G_STATISTICS} -eq 1 ] ; then
							G_RSYNC_PARAM="${G_RSYNC_PARAM} --stats"
						fi
						#
						/usr/bin/rsync ${G_RSYNC_PARAM} "${G_FILENAME_SRC}" > "${G_DST_DIRNAME}/${G_DST_BASENAME}"
						G_FILE_COPIED=$?
						if [ ${G_FILE_COPIED} -eq 0 ] && [ -f "${G_DST_DIRNAME}/${G_DST_BASENAME}" ] ; then
							G_RETVAL=0
							echo "OK: ${G_FILENAME_SRC} copied to ${G_DST_DIRNAME}/${G_DST_BASENAME}"
						else
							G_RETVAL=1
							echo "FAIL: ${G_FILENAME_SRC} not copied to ${G_DST_DIRNAME}/${G_DST_BASENAME}"
						fi
					fi

				fi
			else
				echo "FAIL: destination invalid or not fully specified"
				G_RETVAL=1
			fi
		else
			echo "FAIL: source filename ${G_FILENAME_SRC} not found"
			G_RETVAL=1
		fi
	else
		if [ -z "${G_FILENAME_SRC}" ] ; then
			echo "FAIL: source filename must be specified"
			G_RETVAL=1
		fi
		if [ -z "${G_FILENAME_DST}" ] ; then
			echo "FAIL: destination filename must be specified"
			G_RETVAL=1
		fi
	fi

# clean up 

exit ${G_RETVAL}