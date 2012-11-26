#!/bin/sh
readonly KEY="/root/.ssh/53kf-server.ssh"
readonly LIST="/root/.ssh/ip"
readonly DIR="/home/html/it"
 
### Color setting
RED_COL="\\033[1;31m"  # red color
GREEN_COL="\\033[32;1m"     # green color
BLUE_COL="\\033[34;1m"    # blue color
YELLOW_COL="\\033[33;1m"         # yellow color
NORMAL_COL="\\033[0;39m"
 
### action defination
DATE=`date +%Y%m%d`
CMD="/var/log/nginx/kf.$DATE*"
CMD2="/var/log/53kf/nginx/kf.$DATE*"
 
#i=0
while read LINE;do
        echo "$LINE"|grep -q "^#"
        [ $? = 0 ] && continue
 
#	((i++))
        IP=`echo $LINE|awk '{print $1}'`
        HOST=`echo $LINE|awk '{print $2}'`
#	if [ $i -le 5 ];then
		if [ ! -z $IP ];then
			echo -e "$GREEN_COL|---> $HOST ($IP)   Action: $CMD $NORMAL_COL"
			mkdir -p $DIR/$HOST
			rsync -avz -e "ssh -i $KEY" $IP:$CMD $DIR/$HOST/
			echo -e "$GREEN_COL|---> $HOST ($IP)   Action: $CMD2 $NORMAL_COL"
			rsync -avz -e "ssh -i $KEY" $IP:$CMD2 $DIR/$HOST/
        	fi
#	else
#		i=0
		sleep 3
#	fi
done < $LIST
