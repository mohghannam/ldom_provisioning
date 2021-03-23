#!/bin/bash

ip=$1
ldm_name=$2
ssh root@"${ip}" ldm add-domain -i /root/constrants.xml
ssh root@"${ip}" ldm bind ${ldm_name}

