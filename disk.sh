#!/bin/bash
ip=$1
diskinput=$2
log_path="/var/lib/awx/projects/cdom/logs"
var_path="/var/lib/awx/projects/cdom/all_vars.yml"
repo_path="/var/lib/awx/projects/cdom/disk_repo"
hostname=$(grep -i hostname "${var_path}"  | cut -d ':' -f 2 | xargs echo)
ipaddr=$(grep -i ipaddr "${var_path}"  | cut -d ':' -f 2 | xargs echo)
gateway=$(grep -i gateway "${var_path}"  | cut -d ':' -f 2 | xargs echo)
hostname_pool="/var/lib/awx/projects/cdom/hostnames"
ip_pool="/var/lib/awx/projects/cdom/ips"
#if user not insert disk will going if condition
if [ -z ${diskinput} ] #senario null value
then
	fullpath=$(grep "free" ${repo_path} | head -n 1) # fullpath disk + free
	path=$(grep "free"  ${repo_path} | head -n 1 | cut -d ' ' -f 1 ) # path without free
	if [[ -z ${fullpath} ]] # if the pool not conten free any disk will exit
	then
		echo "$(date +"%m-%d-%y:::%r") :$USER  disk repo not has any disk free  " >> ${log_path}
		sed -i "/^${hostname}$/d" ${hostname_pool}
		sed -i "s|${ipaddr}:${gateway}:.*reserved|${ipaddr}:${gateway}:free|g" ${ip_pool}
		echo "fail"
		exit 0
	fi
	global=$(ssh root@"${ip}"  sudo grep "${path}" /var/opt/SUNWldm/ldom-db.xml  | cut -d '>' -f 2 | cut -d '<' -f 1  ) # path in global constrants
	if [[ ${path} == ${global}  ]] # if take free disk from pool if see disk in constratns will change free word in file to reserved and will exit
	then
		echo "$(date +"%m-%d-%y:::%r") :$USER  intered ${path} which already exist in  constrants file  " >> ${log_path}
		sed  -i "s|${fullpath}|${path} reserved|g"  ${repo_path}
		sed -i "/^${hostname}$/d" ${hostname_pool}
		sed -i "s|${ipaddr}:${gateway}:.*reserved|${ipaddr}:${gateway}:free|g" ${ip_pool}
		echo "fail"
		exit 0
        else # disk free in pool and not found in constrans will add disk & change free to reserved
		sed -i "s|${fullpath}|${path} reserved|g" ${repo_path}
		echo "$(date +"%m-%d-%y:::%r") :$USER  intered ${path} create new disk  " >> ${log_path}
		vol=$(echo "vol$(shuf -i 0-10000000 -n 1)")
                sed -i "s|^disk: .*|disk: ${path}|g" ${var_path}
                sed -i "s|^volume: .*|volume: ${vol}|g" ${var_path}
		uuid=$(echo "bbf6ca21-6aa6-441e-8713-d38a193d4$(shuf -i 0-1000 -n 1)")
		sed -i "s/^uuid: .*/uuid: ${uuid}/g" ${var_path}

	fi
else
	diskname=$(ssh root@${ip} sudo grep "${diskinput}" /var/opt/SUNWldm/ldom-db.xml  | cut -d '>' -f 2 | cut -d '<' -f 1  ) # disk name in constrans
	diskinpool=$(grep "${diskinput}"  ${repo_path} | cut -d ' ' -f 2 ) # cut free or reserved
	pathinpool=$(grep "${diskinput}" ${repo_path} | head -n 1)   # cut full path + free or reserved
	cdom=$(ssh root@$1 sudo ls ${diskinput} 2> /dev/null)
	if [[ $? -gt "1"  ]] # if user write woring disk will exit  
	then
		echo "$(date +"%m-%d-%y:::%r") :$USER  intered ${diskinput} which disk not found please enter correct name  " >> ${log_path}
		sed -i "/^${hostname}$/d" ${hostname_pool}
		sed -i "s|${ipaddr}:${gateway}:.*reserved|${ipaddr}:${gateway}:free|g" ${ip_pool}
		echo "fail"
		exit 0
	fi
	if [[ ${diskinput} == ${diskname} ]] # will chack disk input in constrans if see it will exit
	then
		echo "$(date +"%m-%d-%y:::%r") :$USER  intered ${diskinput} which already exist in  constrants file  " >> ${log_path}
		sed -i "/^${hostname}$/d" ${hostname_pool}
		sed -i "s|${ipaddr}:${gateway}:.*reserved|${ipaddr}:${gateway}:free|g" ${ip_pool}
		echo "fail"
		exit 0
	elif [[ ${diskinpool} == "reserved"  ]] # will check in pool for input disk if disk found and used will exit 
	then
		echo "$(date +"%m-%d-%y:::%r") :$USER  intered ${diskinput} which already exist in  disk repo  " >> ${log_path}
		sed -i "/^${hostname}$/d" ${hostname_pool}
		sed -i "s|${ipaddr}:${gateway}:.*reserved|${ipaddr}:${gateway}:free|g" ${ip_pool}
		echo "fail"
		exit 0
	elif [[ ${diskinpool} == "free"  ]] # will check in pool if is found and free will and disk and change free to reserved
	then
		echo "$(date +"%m-%d-%y:::%r") :$USER  intered ${diskinput} create disk   " >> ${log_path}
		sed  -i "s|${pathinpool}|${diskinput} reserved|g"  ${repo_path}
		vol=$(echo "vol$(shuf -i 0-10000000 -n 1)")
                sed -i "s|^disk: .*|disk: ${diskinput}|g" ${var_path}
                sed -i "s|^volume: .*|volume: ${vol}|g" ${var_path}
		uuid=$(echo "bbf6ca21-6aa6-441e-8713-d38a193d4$(shuf -i 0-1000 -n 1)")
		sed -i "s/^uuid: .*/uuid: ${uuid}/g" ${var_path}

	else # if disk not found in pool will add in pool with reserved word and add di
		echo "${diskinput} reserved" >> ${repo_path}
		echo "$(date +"%m-%d-%y:::%r") :$USER  intered ${diskinput} create new disk and add in pool  " >> ${log_path}
		vol=$(echo "vol$(shuf -i 0-10000000 -n 1)")
                sed -i "s|^disk: .*|disk: ${diskinput}|g" ${var_path}
                sed -i "s|^volume: .*|volume: ${vol}|g" ${var_path}
		uuid=$(echo "bbf6ca21-6aa6-441e-8713-d38a193d4$(shuf -i 0-1000 -n 1)")
		sed -i "s/^uuid: .*/uuid: ${uuid}/g" ${var_path}
	fi	
fi
