#!/bin/bash
# ****************************************************************************
# * Description : Test - simulate DVD-style data by generating randomly
# ****************************************************************************
# * Last commit details:
# * : 1 $
# * : lcowdrey $
# * : 2015-1101 15:59:58 +0100 (Sun, 1 November 2015) $
# * :  $
# *************************************************************/d***************

# globals
	G_RETVAL=0
	G_USE_FALLOCATE=1
	G_USE_DD=0
	G_USE_TREE=0
	G_DISPLAY_FULL_TREE=0
	G_DISPLAY_TREE=0
	G_PARENT_DIR=""
	G_CLEANUP=0
	G_ROOT_DIRECTORY=""
	G_MAX_DEPTH=5
	G_CURRENT_SUB_DIRECTORIES=0
	G_MAX_FILES=11
	G_MAX_VOB_SIZE_MB=9
	G_DIR_PREFIX="VIDEO_TS_"
	G_VOB_PREFIX="VTS_"
	G_VOB_SUFFIX="VOB"
	G_IFO_SUFFIX="IFO"
	G_BUP_SUFFIX="BUP"
	G_VOB_SIZE=0
	G_ORIGINAL_PWD=$(pwd)
	G_JOBS_RUNNING=0
	G_JOBS_STOPPED=0
	G_JOBS_PERCENT=0
	G_JOBS_TOTAL=0
	G_JOBS_OUTSTANDING=0
	G_FILE_DD_SOURCE="/dev/urandom"

# arrays
  	# delete anything that may exist
  	if [ ${#ASCP_FILE_TASKS[@]} -gt 0 ] ; then
		unset ASCP_FILE_TASKS
  	else
      declare -a ASCP_FILE_TASKS
  	fi

# functions
usage ()
{
	echo "Usage: ${0} \ "
	echo "            [--parent|-p {directory} ]              # default: ./"
	echo "            [--max-file-size|-mfs {MB}]             # default: ${G_MAX_VOB_SIZE_MB}MB, whole units only"
	echo "            [--max-depth|-md {number}]              # default: ${G_MAX_DEPTH}, whole units only"
	echo "            [--max-files|-mf {number}]              # default: ${G_MAX_FILES}, whole units only"
	echo "            [--force-file-size|-ffs {MB}]           # whole units only"
	echo "            [--use-dd|-udd]                         # regardless, use dd for temp file creation"
	echo "            [--use-fallocate|-ufa]                  # regardless, use fallocate for temp file creation"
	echo "            [--use-touch|-ut]                       # regardless, use touch for temp file creation"
	echo "            [--display-tree|-dt]                    # display summary tree details"
	echo "            [--display-full-tree|-dft]              # display full tree details inc. files and sizes via tree tool"
	echo "            [--cleanup|-c]                          # remove all temporary items at completion"
	echo "            [--help|-?]"
}

change_dir_down ()
{
	if [ ! -d "${1}" ] ; then
		mkdir -p "${1}" &>/dev/null
	fi
	pushd "${1}" &>/dev/null
}

change_dir_up ()
{
	popd &>/dev/null
}

populate_current_dir ()
{
	local FILES=$[ 1 + $[ RANDOM % $G_MAX_FILES ]]
	for F in $(seq -f "%02g" 1 ${FILES}) ; do
		local VOB_NAME="$(pwd)/${G_VOB_PREFIX}${F}_0"
		local VOB_SIZE=0
		# use specified file size if provided otherwise random size within limits
		if [ ${G_VOB_SIZE} -gt 0 ] ; then
			VOB_SIZE=${G_VOB_SIZE}
		else
			VOB_SIZE=$[ 1 + $[ RANDOM % $G_MAX_VOB_SIZE_MB ]]
		fi
		# use array to hold each file creation for later execution
		if [ ${G_USE_FALLOCATE} -eq 1 ] ; then
			local VOB_BYTES=$((${VOB_SIZE}*1048576))
			ASCP_FILE_TASKS+=("/usr/bin/fallocate --length ${VOB_BYTES} ${VOB_NAME}.${G_VOB_SUFFIX}")
			ASCP_FILE_TASKS+=("/usr/bin/fallocate --length 18432 ${VOB_NAME}.${G_IFO_SUFFIX}")
			ASCP_FILE_TASKS+=("/usr/bin/fallocate --length 92160 ${VOB_NAME}.${G_BUP_SUFFIX}")
		elif [ ${G_USE_DD} -eq 1 ] ; then
			local VOB_COUNT=$((${VOB_SIZE}*1024))
			ASCP_FILE_TASKS+=("/bin/dd if=${G_FILE_DD_SOURCE} of=${VOB_NAME}.${G_VOB_SUFFIX} bs=1024 count=${VOB_COUNT}")
			ASCP_FILE_TASKS+=("/bin/dd if=${G_FILE_DD_SOURCE} of=${VOB_NAME}.${G_IFO_SUFFIX} bs=18432 count=1")
			ASCP_FILE_TASKS+=("/bin/dd if=${G_FILE_DD_SOURCE} of=${VOB_NAME}.${G_BUP_SUFFIX} bs=92160 count=1")
		else
			ASCP_FILE_TASKS+=("/usr/bin/touch ${VOB_NAME}.${G_VOB_SUFFIX}")
			ASCP_FILE_TASKS+=("/usr/bin/touch ${VOB_NAME}.${G_IFO_SUFFIX}")
			ASCP_FILE_TASKS+=("/usr/bin/touch ${VOB_NAME}.${G_BUP_SUFFIX}")
		fi
	done
	G_JOBS_TOTAL=${#ASCP_FILE_TASKS[@]}
}

process_nested_dir ()
{
	if [ $G_CURRENT_SUB_DIRECTORIES -lt $G_MAX_DEPTH ] ; then
		((G_CURRENT_SUB_DIRECTORIES += 1))
		local SUB_DIRECTORIES=$[ 1 + $[ RANDOM % $G_CURRENT_SUB_DIRECTORIES ]]
		for P in $(seq -w 1 $SUB_DIRECTORIES) ; do
			change_dir_down "${G_DIR_PREFIX}${P}"
			populate_current_dir
			if [ $[ RANDOM % 2 ] -eq 1 ] ; then
				process_nested_dir
			fi
			change_dir_up
		done
	fi
}

process_file_tasks ()
{
	G_JOBS_OUTSTANDING=${G_JOBS_TOTAL}
	until [[ $G_JOBS_OUTSTANDING -eq 0 ]] ; do
		G_JOBS_PERCENT=$(bc <<< "scale=2;100-((${G_JOBS_OUTSTANDING}/${G_JOBS_TOTAL})*100)"|cut -d"." -f1)
		echo -ne "INFO: progress $(printf '%3s%%' ${G_JOBS_PERCENT}) "
		local BAR_IND=""
		for B in $(seq 1 $(bc <<< "scale=0;${G_JOBS_PERCENT}/5")) ; do 
			BAR_IND="${BAR_IND}#"
		done
		BAR_LEN=${#BAR_IND}
		while [ ${BAR_LEN} -lt 20 ] ; do 
			BAR_IND="${BAR_IND} "
			((BAR_LEN+=1))
		done
		echo -ne "[${BAR_IND}]\r"
		if [ $G_JOBS_OUTSTANDING -eq 0 ] ; then
			break
		fi
		eval ${ASCP_FILE_TASKS[-1]} &>/dev/null
		unset ASCP_FILE_TASKS[-1]
		G_JOBS_OUTSTANDING=${#ASCP_FILE_TASKS[@]}
	done
    echo -e "\r\nINFO: completed"
}

display_tree ()
{
	# tree details, if available
	if [ ${G_USE_TREE} -eq 1 ] ; then
		if [ ${G_DISPLAY_FULL_TREE} -eq 1 ] ; then
			echo -n "INFO: full tree for " && /usr/bin/tree -s "${G_ROOT_DIRECTORY}"
		elif [ ${G_DISPLAY_TREE} -eq 1 ] ; then
			echo -n "INFO: summary tree for " && /usr/bin/tree -d "${G_ROOT_DIRECTORY}"
		fi
	else
		if [ ${G_DISPLAY_TREE} -eq 1 ] ; then
			echo -n "INFO: summary tree for " && /usr/bin/du -c -h "${G_ROOT_DIRECTORY}"
		fi
	fi	
}

# if fallocate available use that, otherwise check for DD (legacy)
	command -v /usr/bin/fallocate &>/dev/null
	if [ "${?}" -ne 0 ] ; then
		G_USE_FALLOCATE=0
		command v dd &>/dev/null
		if [ "${?}" -eq 0 ] ; then
			echo "INFO: DD available, using as legacy"
			G_USE_DD=1
		else
			G_USE_DD=0
		fi
	fi

# Check command line arguments
	OPTION="${1}"
	while [ $# -gt 0 ] ; do
		case "${OPTION}" in
			--parent|-p)
				shift
				G_PARENT_DIR="$1"
				;;
			--max-file-size|-mfs)
				shift
				G_MAX_VOB_SIZE_MB=$(echo -n "${1}"|cut -d"." -f1|cut -d"-" -f2)
				;;
			--max-depth|-md)
				shift
				G_MAX_DEPTH=$(echo -n "${1}"|cut -d"." -f1|cut -d"-" -f2)
				;;
			--max-files|-mf)
				shift
				G_MAX_FILES=$(echo -n "${1}"|cut -d"." -f1|cut -d"-" -f2)
				if [ ${G_MAX_FILES} -gt 99 ] ; then
					G_MAX_FILES=99
				fi 
				if [ ${G_MAX_FILES} -lt 1 ] ; then
					G_MAX_FILES=1
				fi 
				;;
			--force-file-size|-ffs)
				shift
				G_VOB_SIZE=$(echo -n "${1}"|cut -d"." -f1|cut -d"-" -f2)
				if [ ${G_VOB_SIZE} -lt 1 ] ; then
					G_VOB_SIZE=1
				fi 
				;;
			--cleanup|-c)
				G_CLEANUP=1
				;;
			--use-dd|-udd)
				G_USE_DD=1
				G_USE_FALLOCATE=0
				;;
			--use-fallocate|-ufa)
				G_USE_FALLOCATE=1
				G_USE_DD=0
				;;
			--use-touch|-ut)
				G_USE_FALLOCATE=0
				G_USE_DD=0
				;;
			--display-tree|-dt)
				G_DISPLAY_TREE=1
				;;
			--display-full-tree|-dft)
				G_DISPLAY_FULL_TREE=1
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

# validate optionally supplied parent directory
# if nothing supplied default to current directory
	if [ -z "${G_PARENT_DIR}" ] ; then
		G_PARENT_DIR=$(pwd)
	fi
	echo "INFO: using parent directory ${G_PARENT_DIR}"
	if [ ! -d "${G_PARENT_DIR}" ] ; then
		echo "FAIL: parent directory not found"
		G_RETVAL=1
		exit ${G_RETVAL}
	fi

# check if helper tools available
# see if tree helper function available
	command -v /usr/bin/tree &>/dev/null
	if [ "${?}" -eq 0 ] ; then
		G_USE_TREE=1
	else
		G_USE_TREE=0
		echo "INFO: tree command not available, using du"
	fi

# start
	G_ROOT_DIRECTORY=$(mktemp -d -p $G_PARENT_DIR)
	G_SUB_DIRECTORIES=$[ 1 + $[ RANDOM % $G_MAX_DEPTH ]]
	echo "INFO: random directory depth=${G_SUB_DIRECTORIES}"

	echo "INFO: nested root directory ${G_ROOT_DIRECTORY}"
    if [ ${G_VOB_SIZE} -gt 0 ] ; then
		echo "INFO: file size fixed=${G_VOB_SIZE}MB"
	else
		echo "INFO: file size random range=1MB..${G_MAX_VOB_SIZE_MB}MB"
    fi

    if [ ${G_USE_FALLOCATE} -eq 1 ] ; then
    	echo "INFO: file creation method=fallocate"
    elif [ ${G_USE_DD} -eq 1 ] ; then
    	echo "INFO: file creation method=dd"
    else
    	echo "INFO: file creation method=touch"
    fi

    # generate structure and content
    change_dir_down "${G_ROOT_DIRECTORY}"
    process_nested_dir
	cd ${G_ORIGINAL_PWD}
	process_file_tasks
	display_tree

# clean up 
  	# delete anything that may exist
  	if [ ${#ASCP_FILE_TASKS[@]} -gt 0 ] ; then
		unset ASCP_FILE_TASKS
  	fi
	if [ ${G_CLEANUP} -eq 1 ] ; then
		if [ -d "${G_ROOT_DIRECTORY}" ] ; then
			rm -R -f "${G_ROOT_DIRECTORY}" &>/dev/null
		fi
	fi

exit ${G_RETVAL}