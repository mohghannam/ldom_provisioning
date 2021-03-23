#!/bin/bash
HOSTNAME=$1
LOGFILE="/var/lib/awx/projects/cdom/logs"
VAR_PATH="/var/lib/awx/projects/cdom/all_vars.yml"
REPO_PATH="/var/lib/awx/projects/cdom/hostnames"
#HOSTNAME_VLAIDATION
#check if hostname is already used by checking file
#if not, append hostname to file
#otherwise exit
#TODO: check if ldom with hostname is exists in cdom 

#Hostname not given, exit
if [ -z ${HOSTNAME} ]; then
	echo 'Incorrect Usage: Atleast a hostname must be given'
	echo "$(date +"%m-%d-%y:::%r")" .user $USER ERROR: Value for Hostname must be given >> ${LOGFILE}
	echo 'fail'
        exit 0
fi
#check if hostname already exists in file
grep "^${HOSTNAME}$" ${REPO_PATH}
if [ $? -eq 0 ]; then
        echo "$(date +"%m-%d-%y:::%r")" .user $USER ERROR: Hostname vlaidation failed. Hostname already used >> ${LOGFILE}
	echo 'fail'
        exit 0
else
        echo "${HOSTNAME}" >> ${REPO_PATH}
	sed -i "s/^hostname: .*/hostname: ${HOSTNAME}/g" ${VAR_PATH}
fi
