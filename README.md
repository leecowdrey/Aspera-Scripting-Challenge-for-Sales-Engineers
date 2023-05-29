# Aspera - SE Challenge

2015 interview scripting challenge for want to be Sales Engineers

The following six (6) scripting questions are used as a diagnostic tool to assess applicant skills. Scripting is not a primary goal of positions where this challenge is given, but applicants are expected to provide a best effort to answering these questions. Answers need to be submitted one (1) week after receiving this scripting challenge.
Applicant should assume the target platform is Linux. Answers for Windows or Mac may be accepted in limited circumstances if pre­approved.

Script submission will consist of a tar/tgz/zip file containing a script file for each question and an optional README if necessary.
The files can be submitted with renamed extensions to overcome spam filters.
Accepted scripting languages are bash/ksh, perl, ruby, and/or python for questions 1 and 2, 4, 5, and 6. Question 3 needs to be in bash/ksh.
If pre­approved to submit script answers for Windows, only Powershell is allowed.
At a minimum, two (2) answers need to be submitted for consideration, and candidates are encouraged to complete more that two.

● Write a script that makes a REST call to http://time.jsontest.com and uses the result to compare against the localhost’s time/date setting. Script result should note the systems’ discrepancy between the times in seconds.

● Write a script that can copy a file, without using cp. The script will take two command line parameters: source file and destination file. Describe the performance implications of the approach that you took and compare it to other methods of copying a file.

● Devise a method for creating temporary file data for use in testing file transfer. The result of the script should be a directory that may have one or more nested directories (quantity randomly determined). Inside these directories are a random number of files in each directory. The files should be large (greater than 1MB) and mimic a collection of data. Applicant is encouraged to determine the make­up of the collection, but here are a couple examples:

○ a collection of frame images in sequential order
○ an archive of video files organized by title.

Please note rationale in the collection chosen, and how the files were generated. What optimizations or considerations need to be made.

● Create a script that will SSH into a remote host and install the user's SSH public key. Assume a target host is Linux. Solution does not need to cover every edge case, but you will need to describe pitfalls with your approach, and how you would address those issues.

● Write a script that periodically executes. This script will check disk space utilization of a defined volume/directory that is passed to it. It will write to a configured file a log entry that indicates the expected date the storage will fill up based on the growth pattern of the storage.


## Test 1

Host OS:       Ubuntu Desktop, 64bit, version 15.04
Language Used: GNU BASH, version 4.3.30(1)
		Dependencies:  curl
               jq (optional) 

Files:         lc_1.sh

Parameters:    Optional, override test URL; --url (or -u)
               Optional, override mime format; --mime-format (or -f)
               Optional, usage help; --help (or -?)

Example(1):    ./lc_1.sh
Example(2):    ./lc_1.sh --url http://date.jsontest.com/
Example(3):    ./lc_1.sh --help

Commentary:    If jsontest.com reports "over usage", then repeat the execution
               when jsontest.com has usage credits, or accept the included
               sample JSON file that the script will create and process when
               "over usage" is detected

## Test 2

Host OS:       Ubuntu Desktop, 64bit, version 15.04
Language Used: GNU BASH, version 4.3.30(1)
Dependencies:  none 

Files:         lc_2.sh
               script_log.tgz

Parameters:    none

Example(1):    ./lc_2.sh

Commentary:    none

## Test 3

Host OS:       Ubuntu Desktop, 64bit, version 15.04
Language Used: GNU BASH, version 4.3.30(1)
Dependencies:  cat
               rsync (optional) 

Files:         lc_3.sh

Parameters:    Source filename; --source (or -s)
               Destination filename or directory; --destination (or -d)
               Optional, make destination paths if not existing; --make-paths (or -m)
               Optional, overwrite destination filename if exists; --overwrite (or -o)
               Optional, preserve file permissions on destination; --preserve-permissions (or -pp)
               Optional, preserve owner on destination; --preserve-owner (or -po)
               Optional, display timing statistics after copy; --statistics (or -s)
               Optional, force use of cat (default); --cat (or -c)
               Optional, force use of rsync (if available); --rsync (or -r)
               Optional, usage help; --help (or -?)

Example(1):    ./lc_3.sh --source /tmp/somefile.txt --destination /home/user/ -pp
Example(2):    ./lc_3.sh -s /tmp/somefile.txt -d /home/user/newfile.txt -pp --preserve-owner
Example(3):    ./lc_3.sh --source /tmp/somefile.txt -d /home/user/ --rsync -s
Example(4):    ./lc_3.sh -s /tmp/somefile.txt --destination /home/user/newfolder/newfile.txt --make-paths
Example(5):    ./lc_3.sh --help

Commentary:    By default cp is faster than cat as cp does not expand sparse holes within files.
               Copy performance via any method is restricted by any of:
                a) Using the same physical disk for simultanously read/write I/O operations
                b) Kernel I/O cache
                c) State of the file associated file system allocation tables (minimal)
                d) Process buffer (memory) space available for read/write I/O operations
                e) Read/write performance and bandwidths limits of included controller interfaces
                f) Read/write performance and bandwidths limits of physical disks (platters vs SSD)

               cat or any other block read/write tools, can have associated performance increased
               by means of comparing the source and destination files (if destination already exists).
               This comparison by means of a checksum can be used to determine if the both files are
               identical and as such the source file can be skipped. When differences exist, additional
               methods can be used to divide the source file in to managable chunks, which each chunk
               being compared for differences and consequently only the differences applied to the
               destination file. rsync undertakes this when the destination file already exists, but
               this can cause delays when producing checksums of large files. Further increasing
               memory caching (via Kernel or within the used tool as larger buffers) can reduce the
               conflict of read vs. write I/O operations against an individual file but due to the 
               size of some files, there may not be sufficient free memory available and as such
               the managable chunks method can be used again for utilise what memory is available.

## Test 4

Host OS:       Ubuntu Desktop, 64bit, version 15.04
Language Used: GNU BASH, version 4.3.30(1)
Dependencies:  dd
               fallocate (optional)
               tree (optional)

Files:         lc_4.sh

Parameters:    Optional, destination parent folder, default is current; --parent (or -p)
               Optional, maximum (not minimum) size of each data file; --max-files-size (or -mfs)
               Optional, maximum nested folder depth; --max-depth (or -md)
               Optional, maximum number of files in each folder; --max-files (or -mf)
               Optional, exact file size of data file; --force-file-size (or -ffs)
               Optional, use DD and /dev/urandom to create files; --use-dd (or -udd)
               Default,  use FALLOCATE to create files; --use-fallocate (or -ufa)
               Optional, use TOUCH to create zero size files; --use-touch (or -ut)
               Optional, display nested tree summary; --display-tree (or -dt)
               Optional, display full tree and files; --display-full-tree (or -dft)
               Optional, remove all generated directories and files and the end; --cleanup (or -c)
               Optional, usage help; --help (or -?)

Example(1):    ./lc_4.sh --parent /home/aspera/dvd --display-tree
Example(2):    ./lc_4.sh -p /home/aspera/dvd --max-depth 11 --max-files 9 --use-dd
Example(3):    ./lc_4.sh --help

Commentary:    The layout followed was based on the DVD-Video file system structure, though with some
               alterations to support unlimited levels of nesting.
               For fast tests, it is recommended to use the defaults of fallocate, to create files purely
               by means of updating file system allocation tables. However this results in zero-filled
               sparse files which are no good for simulating real-world DVD-Video material required to
               demonstrate the abilities of compression and transport protocols. For this reason, the
               recommendation is to specify the use of DD (--use-dd) to ensure any generated file is
               populated with random data. This means the creation will take longer (and a progress bar
               will be displayed) but will generate more realistic files. Performance could be further
               enhanced by incorpating a batch generation so that more than one file production is
               undertaken at any point in time; however extreme care will need to be taken to ensure
               the host is not overloaded when using larger of nested folders and/or large files.

## Test 5

Host OS:       Ubuntu Desktop, 64bit, version 15.04
Language Used: GNU BASH, version 4.3.30(1)
Dependencies:  ping
               ping6
               sshpass
               ssh-keyscan
               ssh-copy-id
               ssh-keygen

Files:         lc_5.sh

Parameters:    Target host hostname or IP address; --host (or -h)
               Public key file to install; --public-key-file (or -f)
               Optional, SSH port number; --port (or -p)
               Optional, target host username; --username (or -u)
               Optional, target host password; --password (or -p)
               Optional, target host password via environment variable; --password-env (or -pe)
               Optional, target host password via local file; --password-file (or -pf)
               Optional, usage help; --help (or -?)

Example(1):    ./lc_5.sh --host 127.0.0.1 --port 22 --public-key-file /home/user/.ssh/id_rsa.pub --password Bing0
Example(2):    .export LC5_PASS="Bing0" && /lc_5.sh -h 192.168.3.1 -u aspera -f rsa_key.pub --password-env LC5_PASS
Example(3):    echo "Bing0" > pass.txt && ./lc_5.sh -h 192.168.3.1 --public-key-file rsa_key.pub --password-file pass.txt
Example(4):    echo "Bing0"|/lc_5.sh -h 192.168.3.1 -f rsa_key.pub --username aspera
Example(5):    ./lc_5.sh --help

Commentary:    This script covers the majority of use cases for transferring a SSH public key
               to a target system. Validating of target host by means of PING and SSH subsystem
               responses ensure the process is under control and each step verified:

                a) PING (IPv4, IPv6, FQDN) - verifies target system is reachable over IP network
                b) SSH Key Scan - verifies an SSH subsystem is responding to external requests
                c) SSH Key Gen - verifies a public and/or private key is valid so good keys are used
                d) Password - source is verfied (file, environment variable, stdin) to ensure a value
                   is supplied; any values are passed securely to SSHPASS in order to automate the
                   SSH password-based authentication prior to key transfer
                e) Username - by default the local username is used as the remote username, meaning
                   one less item of data that has to be specified; it can be overridden as needed
                f) SSH Copy Id - undertakes the necessary creation of .ssh directory, either creating
                   or updating the file authorized_keys with the specified public key and updating 
                   file permissions. SSH Copy Id will also ensure that no key will be duplicated 
                   within the file authorized_keys meaning this test script can be executed 
                   repeatedly against the same server using the same key without any issues

               One use case that has not been included is using a running SSH Agent as the source
               for the public keys rather than one being specified via the command line. 
               ssh-copy-id will though copy keys found within the local SSH Agent buffer if no 
               other key file is supplied and as such is minimal effort to incorporate, however
               it means the risk of more than one public key is copied over.
			   
## Test 6

Host OS:       Ubuntu Desktop, 64bit, version 15.04
Language Used: GNU BASH, version 4.3.30(1)
Dependencies:  stat
               date
               du
               sudo
               systemctl (Ubuntu 15.04 upwards or other systemctl based distributions)

Files:         lc_6.sh
               lc_6_agent.sh
               lc_6.cfg
               lc_6_install.sh
               lc_6_uninstall.sh

Operation:     This can be either installed as a system service (1) and/or requested to run as a
               normal user process, interactively or in the background (2).


Operation(1) As System Service:

Install:       Execute lc_6_install.sh within the same directory as the other specified files
Uninstall:     Execute lc_6_uninstall.sh within the same directory as the other specified files

Usage:         # to start the service without using the included defaults
                  sudo service lc_6 start

               # to change monitored folder via editing configuration file:
                 sudo vi /etc/default/lc_6
                 .. change values of G_FOLDER, G_LOG_FILE, G_INTERVAL
                 sudo service lc_6 stop && sleep 60 && sudo service lc_6 start

               # view log output via:
                 sudo service lc_6 status

               # or
                 sudo tail -f /var/log/lc_6.log

Example(1):    sudo service lc_6 start
Example(2):    sudo service lc_6 status && sudo tail -10 /var/log/lc_6.log
Example(3):    sudo service lc_6 stop


Operation(2) As A User Process:

Files:         lc_6_agent.sh (or lc_6_agent if previously installed as system service)

Parameters:    Directory to monitor; --folder (or -f)
               Log file to populate, if not specified random file in /tmp will be used; --log-file (or -l)
               Optional, interval in whole minutes; --interval (or -i)
               Background directive, must be included if you wish the process to detach; --background (or -bg)

Example(1):    ./lc_6_agent.sh --folder /tmp --log-file /home/user/tmp_monitor.log --interval 5 -bg
Example(2):    ./lc_6_agent.sh -f /tmp -bg
Example(3):    lc_6_agent -f /tmp --log-file /home/user/tmp_monitor.log --interval 10 -bg


Commentary:    When using as a service will automatically start at boot time until its manually removed
               When using as a background user process, then the process must be manually 
               terminated, using: kill -s SIGTERM {PID}
               Minimal effort would be required to the install/uninstall scripts to support the older
               style System-V init script, especially on RedHat Linux based distributions where by
               chkconfig would be used instead of systemctl and update-rc.d
			   