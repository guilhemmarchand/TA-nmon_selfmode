#!/bin/sh

# set -x

# Program name: nmon_manage.sh
# Purpose - nmon simple script designed to call associated libs and manage nmon data
# Author - Guilhem Marchand
# Disclaimer:  this provided "as is".
# Date - Jan 2016

# Jan 2015, Guilhem Marchand: Initial version
# 2016/07/17, Guilhem Marchand: Change expected structure message log level to WARN

# Version 1.0.1
#

# For AIX / Linux / Solaris

#################################################
## 	Your Customizations Go Here            ##
#################################################

# hostname
HOST=`hostname`

NMON_BIN=${SPLUNK_HOME}/etc/apps/TA-nmon_selfmode
NMON_VAR=${SPLUNK_HOME}/var/log/nmon

if ! [ -d ${NMON_BIN} ]; then
    echo "`date`, ${HOST} ERROR, The NMON_BIN directory full path provided could not be found (we tried: ${NMON_BIN}"
	exit 1
fi

if ! [ -d ${NMON_VAR} ]; then
    mkdir ${NMON_VAR}
fi

# Remove any existing temp files
rm ${NMON_VAR}/nmon_manage.sh.tmp.*

for nmon_file in `find ${NMON_VAR}/var/nmon_repository -name "*.nmon" -type f -print`; do

    # Verify Perl availability (Perl will be more commonly available than Python)
    PERL=`which perl >/dev/null 2>&1`

    if [ $? -eq 0 ]; then

        # Use Perl to get PID file age in seconds
        perl -e "\$mtime=(stat(\"$nmon_file\"))[9]; \$cur_time=time();  print \$cur_time - \$mtime;" > ${NMON_VAR}/nmon_manage.sh.tmp.$$

    else

        # Use Python to get PID file age in seconds
        python -c "import os; import time; now = time.strftime(\"%s\"); print(int(int(now)-(os.path.getmtime('$nmon_file'))))" > ${NMON_VAR}/nmon_manage.sh.tmp.$$

    fi

    nmon_age=`cat ${NMON_VAR}/nmon_manage.sh.tmp.$$`
    rm ${NMON_VAR}/nmon_manage.sh.tmp.$$

    # Only manage nmon files updated within last 5 minutes (300 sec) minimum to prevent managing ended nmon files
    if [ ${nmon_age} -lt 300 ]; then
        cat $nmon_file | ${NMON_BIN}/bin/nmon2csv.sh --mode realtime
    fi

done

exit 0
