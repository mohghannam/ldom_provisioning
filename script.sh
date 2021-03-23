#!/bin/bash
#x=5s
log_path="/var/lib/awx/projects/cdom/logs"
repo_path="/var/lib/awx/projects/cdom/all_vars.yml"
cdom_path="/var/lib/awx/projects/cdom/cdom_repo"
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
                       # sed -i "/^${HOSTNAME}$/d" ${HOSTNAME_POOL}
                        echo "$(date +"%m-%d-%y:::%r")" .user $USER. $1 incorrect ip  format write valid ip for cdom >> ${log_path}
                        echo 'fail'
                        exit 0
                fi
        else
               # sed -i "/^${HOSTNAME}$/d" ${HOSTNAME_POOL}
                echo "$(date +"%m-%d-%y:::%r")" .user $USER. $1  incorrect ip format write valid ip for cdom  >> ${log_path}
                echo 'fail'
                exit 0
        fi
}

if  [ -z "$1" ]
#s1 is the input i am gonna tack from the user to chech it is cdom or not  
#ip=$(grep "$1" ${cdom_path} | cut -d : -f 2)
#echo "ip is $ip"
#first if condetion chech the input if it null it will pick up ip from cdom repo and make rundrubin
# if it does not exist it will access othe if statment
then
        # round roubin
        round=$(tail -n 1 ${cdom_path})
        #take the last line
        echo $round
        # make it the first ip in the file 
        echo $round | cat - ${cdom_path} > temp && mv -f temp ${cdom_path}
        #delet the last line 
        #sed -i '$ d' ${cdom_path}
        # sending logs to specif fill 
       # usedip= $($round | cut -d: -f 2 )
        used_ip=$(tail -n 1 ${cdom_path} | cut -d : -f 2)
        #echo "$round"
        echo "used ip is $used_ip"
        echo "$(date +"%m-%d-%y:::%r") :$USER have not enetered any ip the $used_ip will be used  as cdom  " >> ${log_path}
        echo "success"
        echo "used ip is ${round}"
        sed -i "s/^cdom_ip: .*/cdom_ip: ${used_ip}/g" ${repo_path}
        sed -i '$ d' ${cdom_path}
else
#second if statment to chech if the enterd ip is exist inside the cdom repo
#if it exist it will do nothing if it is not exist it will acess other if statment 
    ipformat $1
    if  grep -q "$1" ${cdom_path}  
    then
	echo " is exist"
        sed -i "s/^cdom_ip: .*/cdom_ip: $1/g" ${repo_path}
        echo "$(date +"%m-%d-%y:::%r") :$USER  intered $1 which already exist in  cdom repo  " >> ${log_path}
        echo "success"
    else
        echo " does not exist"
        check_cdom=$(ssh -i=/root/.ssh/id_rsa root@$1 virtinfo -a   | grep primary | cut -d: -f 2 | sed -e 's/^[[:space:]]*//')
        #sleep 10
        # the third if statment to check if the entered ip  is a controle domain or not 
        if [ "$check_cdom" == "primary" ]
        then
            echo "this is controle domain"
            sed -i "s/^cdom_ip: .*/cdom_ip: $1/g" ${repo_path}
            echo "$(date +"%m-%d-%y:::%r") :$USER  intered $1 and it is valied cdom ip " >> ${log_path}
            echo "success"
        else
            echo "this is not controle domain"
            echo "$(date +"%m-%d-%y:::%r") :$USER  intered $1 and it is not valied cdom ip " >> ${log_path}
            echo "fail"
        fi
    fi
fi 

