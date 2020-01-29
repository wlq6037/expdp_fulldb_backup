#!/bin/bash

#oracle datapump backup script
#create by: wlq6037@163.com
#bug fix contact: wlq6037@163.com

#debug mod
#set -euxo pipefail
#for product env
set -euo pipefail

#timestamp var
TIMESTAMP=$(date "+%Y%m%d_%Hh%M")

#get current path
SETUP_PATH=`pwd`
cd $SETUP_PATH
LOG_PATH="$SETUP_PATH/log"
[ -d ${LOG_PATH} ] && echo "Log PATH Exists" || mkdir -p $SETUP_PATH/log
LOG_RECORD=backup_$(date "+%d_%m_%Y").log
[ -f ${LOG_PATH}/${LOG_RECORD} ] && echo "Log file Exists" || touch ${LOG_PATH}/${LOG_RECORD}

CONF_FILE=$SETUP_PATH/oradb.conf
[ -f ${CONF_FILE} ] && echo "Config file Exists" || (echo "Config file must be set!!!"&&exit 1)
#logo banner
function logo_banner(){
    if [ -s ${LOG_PATH}/${LOG_RECORD} ];
    then
        echo "####################################################" >> ${LOG_PATH}/${LOG_RECORD}
        echo "#       Oracle Datapump Backup Script Setup        #" >> ${LOG_PATH}/${LOG_RECORD}
        echo "#          Auther:wangliqiang@gmail.com            #" >> ${LOG_PATH}/${LOG_RECORD}
        echo "#        Contact: wangliqiang@deewinfl.com         #" >> ${LOG_PATH}/${LOG_RECORD}
        echo "####################################################" >> ${LOG_PATH}/${LOG_RECORD}
        echo ""                                                     >> ${LOG_PATH}/${LOG_RECORD}
    fi
}

#log record
function write_to_log(){
        YEAR=$(date +%Y)
        MONTH=$(date +%m)
        DAY=$(date +%d)
        HOUR=$(date +%H)
        MINUTES=$(date +%M)
        SECONDS=$(date +%S)
        LOG_TIMESTAMP="$YEAR $MONTH $DAY - $HOUR:$MINUTES:$SECONDS"
        echo "$LOG_TIMESTAMP => $LOG_MSG" >> ${LOG_PATH}/${LOG_RECORD}
}

#check root privilege
function am_i_root(){
    LOG_MSG="Checking user..."
    write_to_log
    who_am_i=$(whoami)
    if [ $who_am_i != "root" ];
    then
        LOG_MSG="You are running expdp_fulldb_backup with $who_am_i user, but you need to be ROOT to run properly this backup script."
        write_to_log
        LOG_MSG="Come back when you will be Root. Exit"
        write_to_log
        exit
    else 
        LOG_MSG="user Ok"
        write_to_log
    fi
}

#load VARs from default config file ./oradb.conf
function set_source_variables () {
    printf "Config file found,checking default config\n" >&2
    . ${CONF_FILE}
    ORACLE_SID="${ORACLE_SID:-orcl}"
    HOST="${HOST}"
    [[ -z "${HOST}" ]]&& echo "HOST must be set!!!"&&exit 1
    USER="${USER}"
    [[ -z "${USER}" ]]&& echo "USER must be set!!!"&&exit 1
    PASSWD="${PASSWD}"
    [[ -z "${PASSWD}" ]]&& echo "PASSWD must be set!!!"&&exit 1
    ORACLE_BACKUP_DIR="${ORACLE_BACKUP_DIR:-/data/oracle_backup}"
    [ -d ${ORACLE_BACKUP_DIR}/$(date "+%Y%m%d") ] && echo "Backup DIR Exists" || (mkdir -p ${ORACLE_BACKUP_DIR}/$(date "+%Y%m%d") && chown -R oracle:oinstall ${ORACLE_BACKUP_DIR} && chmod -R 775 ${ORACLE_BACKUP_DIR})
    LOG_FILE=backup_${ORACLE_SID}_$(date "+%d_%m_%Y").log
    DMP_FILE=backup_full_${ORACLE_SID}_${TIMESTAMP}.dump
}

#####main loop
#clear
LOG_MSG="**** Start backup task on $(date '+%D %T') ****"
#init process
write_to_log
logo_banner
am_i_root
set_source_variables
#backup process
LOG_MSG="**** \n Backup process STARTING ****"
write_to_log
su - oracle<<EOF
expdp \"/ as sysdba\" full=y logfile=${LOG_FILE} dumpfile=${DMP_FILE}
exit;
EOF
LOG_MSG="**** \n Datapump export data SECCEED ****"
write_to_log
#compress process
LOG_MSG="**** \n Compress process STARTING *****"
write_to_log
mv ${ORACLE_BACKUP_DIR}/${DMP_FILE} ${ORACLE_BACKUP_DIR}/$(date "+%Y%m%d")
mv ${ORACLE_BACKUP_DIR}/${LOG_FILE} ${ORACLE_BACKUP_DIR}/$(date "+%Y%m%d")
tar --remove-files -czvf ${ORACLE_BACKUP_DIR}/backup_full_${ORACLE_SID}_${TIMESTAMP}.tar.gz ${ORACLE_BACKUP_DIR}/$(date "+%Y%m%d") >> ${LOG_PATH}/${LOG_RECORD}
LOG_MSG="**** \n Compress process FINISHED *****"
write_to_log
#sftp transfer process
LOG_MSG="**** \n Transfer process STARTING *****"
write_to_log
sshpass -p "${PASSWD}" sftp -v -o StrictHostKeyChecking=no ${USER}@${HOST} << EOT >>${LOG_PATH}/${LOG_RECORD}
put ${ORACLE_BACKUP_DIR}/backup_full_${ORACLE_SID}_${TIMESTAMP}.tar.gz
bye
EOT
LOG_MSG="**** \n Transfer process FINISHED *****"
write_to_log
# maintenance process
LOG_MSG="**** \n Maintenance process STARTING *****"
write_to_log
find ${ORACLE_BACKUP_DIR} -name "*.tar.gz" -mtime +3 -exec rm -f {} \;>>${LOG_PATH}/${LOG_RECORD}
find ${LOG_PATH} -name "*.log" -mtime +30 -exec rm -f {} \;>>${LOG_PATH}/${LOG_RECORD}
LOG_MSG="**** \n Maintenance process FINISHED *****"
write_to_log
LOG_MSG="**** \n Backup process COMPLETED!!! *****"
write_to_log