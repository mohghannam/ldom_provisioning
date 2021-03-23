#!/bin/bash


#Get inputs for hostname & IP
IPADDR_CIDR=$1
GATEWAY=$2
LOGFILE='/var/lib/awx/projects/cdom/logs'
HOSTNAME_POOL='/var/lib/awx/projects/cdom/hostnames'
IP_POOL='/var/lib/awx/projects/cdom/ips'
ALL_VARS='/var/lib/awx/projects/cdom/all_vars.yml'

#GET HOSTNAME FROM Global Vars
HOSTNAME=$(grep -i hostname "${ALL_VARS}"  | cut -d ':' -f 2 | xargs echo)

#IP_VALIDATION
#check if ip is null or given

#if null, get an ip from the file with the ips pool
#use VAL_FROM_FILE for sed and IPADDR to cut the ip part
#check if VAL_FROM_FILE is empty to see if there are free ips available in the ip pool file.
#if no free ips, exit and remove hostname from file
#else reserve ip from pool



#Function to check format of ip given by user is valid. If not exit and remove hostname
#seperate ip into arrary and check array indeces. First check if ip is made of 4 octets of
# 3 numbers each if not fail, if yes check each octet is less than 255.
function ipformat() {
        local ip=$1
        local status=1

        if [[  $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                OIFS=$IFS
                IFS='.'
                iparray=($ip)
                IFS=$OIFS
                echo "${iparray[0]} ${iparray[1]} ${iparray[2]} ${iparray[3]}"
                if [[ ${iparray[0]} -le 255 && ${iparray[1]} -le 255 && ${iparray[2]} -le 255 && ${iparray[3]} -le 255 ]]; then
                        echo "valid ip"
                else
			sed -i "/^${HOSTNAME}$/d" ${HOSTNAME_POOL}
                        echo "$(date +"%m-%d-%y:::%r")" .user $USER. $1 incorrect ip  format >> ${LOGFILE}
			echo 'fail'
                        exit 0
                fi
        else
		sed -i "/^${HOSTNAME}$/d" ${HOSTNAME_POOL}
                echo "$(date +"%m-%d-%y:::%r")" .user $USER. $1  incorrect ip format >> ${LOGFILE}
		echo 'fail'
                exit 0
        fi
}

#user has given both IP/CIDR and Gateway
#call format function to check ip and gateway format is valid
if [[ $# -eq 2 ]]; then 
	IPADDR=$(echo ${IPADDR_CIDR} | cut -d '/' -f 1)
	if [ ! -z ${IPADDR} ]; then 
		ipformat ${IPADDR}
	fi


#	echo -ne '\n' | telnet ${IPADDR} 22 | grep -i '^Conneted'
#	if [[ $? -ne 0 ]]; then
#		echo "$(date +"%m-%d-%y:::%r")" .user $USER IP already used by another ldom >> ${LOGFILE}
#		echo 'fail'
#		exit 1
#	fi


#call function to check gateway format
	if [ ! -z ${GATEWAY} ]; then 
		ipformat ${GATEWAY}
	fi
#updates repos with given ip and gateway
	echo "IP is not null"
        #check if ip given is already used in pool. if reserved quit, if free mark as reserved.
        IP_IN_POOL=$(grep ${IPADDR_CIDR} ${IP_POOL} | cut -d ':' -f 3)
        if [[ ${IP_IN_POOL} == 'reserved' ]]; then
        	sed -i "/^${HOSTNAME}$/d" ${HOSTNAME_POOL}
        	echo "$(date +"%m-%d-%y:::%r")" .user $USER IP already reserved in pool file >> ${LOGFILE}
        	echo 'fail'
        	exit 0
        elif [[ ${IP_IN_POOL} == 'free' ]]; then
          sed -i "s|${IPADDR_CIDR}:${GATEWAY}:.*free|${IPADDR_CIDR}:${GATEWAY}:reserved|g" ${IP_POOL}
        else
          echo "${IPADDR_CIDR}:${GATEWAY}:reserved" >> ${IP_POOL}
          sed -i "s|^IPADDR_CIDR: .*|IPADDR_CIDR: ${IPADDR_CIDR}|g" ${ALL_VARS} 
          sed -i "s|^gateway: .*|gateway: ${GATEWAY}|g" ${ALL_VARS}
        fi
elif [[ $# -eq 0 ]]; then
	if [ -z ${IPADDR_CIDR} ]; then
        	echo "IP is null"
        	VAL_FROM_FILE=$(grep '.*free.*' ${IP_POOL} | head -1)
        	#Pool of IPS empty, exit and remove hostname from hostname file
        	if [[ -z ${VAL_FROM_FILE} ]]; then
        	   echo "$(date +"%m-%d-%y:::%r")" .user $USER ERROR: No Free IPs in IP pool file >> ${LOGFILE}
		   echo 'fail'
        	   sed -i "/^${HOSTNAME}$/d" ${HOSTNAME_POOL}
        	   exit 0
        	fi
        	IPADDR=$(echo ${VAL_FROM_FILE} | cut -d ':' -f 1)
                GW=$(echo ${VAL_FROM_FILE} | cut -d ':' -f 2)
        	sed -i "s|${VAL_FROM_FILE}|${IPADDR}:${GW}:reserved|g" ${IP_POOL}
		sed -i "s|^ipaddr: .*|ipaddr: ${IPADDR}|g" ${ALL_VARS}
                sed -i "s|^gateway: .*|gateway: ${GW}|g" ${ALL_VARS}
	fi
else
        sed -i "/^${HOSTNAME}$/d" ${HOSTNAME_POOL}
        echo "$(date +"%m-%d-%y:::%r")" .user $USER. You must specify an IP/CIDR and a Gateway if you will set a static connection >> ${LOGFILE}
	echo "fail"
	exit 0

fi


echo "VAL_FROM_FILE is $VAL_FROM_FILE"
echo "IP is $IPADDR"
