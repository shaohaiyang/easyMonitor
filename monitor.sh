#!/bin/sh
read ARG
FILE=`echo $ARG|cut -d@ -f1`
SORT=`echo $ARG|cut -d@ -f2`
NUM="20"
DIR="/home/html/it"
SUM="/tmp/sum"
LOAD="/tmp/uptime"
IP_LOG="/tmp/ip"
BAND="/tmp/band"
BLACK="/tmp/blacklist"
BADUSER="/tmp/stoplist"

echo "$FILE $SORT" > /tmp/opt
case "$SORT" in
	pv)
		HOST=`echo $FILE | cut -d'/' -f1`
		IP=`grep -w $HOST /root/.ssh/ip|awk '{print $1}'`
		echo "$HOST($IP)<br>"
		sort -k3nr $DIR/$FILE | head -n$NUM > $IP_LOG
		echo "<table border=5><tr><td>Sort No.</td><td>Company ID</td><td>BandWidth (B) </td><td>PV !!!</td></tr>"
		cat -n $IP_LOG|sed -r -e 's:^ *::' -e 's:\t: :g'|sed -r 's: :</td><td>:g'|sed -r 's:(.*):<tr><td>\1</td></tr>:'
		echo "</table>"
		;;
	bandwidth)
		HOST=`echo $FILE | cut -d'/' -f1`
		IP=`grep -w $HOST /root/.ssh/ip|awk '{print $1}'`
		echo "$HOST($IP)<br>"
		sort -k2nr $DIR/$FILE | head -n$NUM > $BAND
		echo "<table border=5><tr><td>Sort No.</td><td>Company ID</td><td>BandWidth (B)!!!</td><td>PV</td></tr>"
		cat -n $BAND|sed -r -e 's:^ *::' -e 's:\t: :g'|sed -r 's: :</td><td>:g'|sed -r 's:(.*):<tr><td>\1</td></tr>:'
		echo "</table>"
		;;
	sum)
		HOST=`echo $FILE | cut -d'/' -f1`
		IP=`grep -w $HOST /root/.ssh/ip|awk '{print $1}'`
		echo "$HOST($IP)<br>"
		DATE=`echo $FILE|awk -F"result-" '{print $2}'`
		TIME=`echo $DATE | cut -c-8`
		HOUR=`echo $DATE | rev | cut -c-2 | rev`
		FILE=`echo $FILE|awk -F"result-" '{print $1}'`
		rm -rf $SUM
		cat "$DIR/$FILE"*"" > $SUM
		awk '{a[$1]+=$2;b[$1]+=$3} END{for(i in a) print i,a[i],b[i]}' $SUM | sort -k3nr | head -n$NUM > $IP_LOG
		echo "<table border=5><tr><td>Sort No.</td><td>Company ID</td><td>BandWidth (B) </td><td>PV !!!</td></tr>"
		cat -n $IP_LOG|sed -r -e 's:^ *::' -e 's:\t: :g'|sed -r 's: :</td><td>:g'|sed -r 's:(.*):<tr><td>\1</td></tr>:'
		echo "</table>"
		;;
	ping)
		IP=`grep -w $FILE /root/.ssh/ip|awk '{print $1}'`
		/usr/bin/get_status.sh $IP $DIR/$FILE
		echo "$FILE($IP)<br>"
		echo "<table border=5><tr><td>西安电信</td><td>大连网通</td><td>深圳电信</td><td>北京网通</td><td>浙江电信</td><td>济南网通</td></tr>"
		echo "<tr><td>"
		cat $DIR/$FILE/$IP.html | tr '\n' '@'|sed -r 's:@:</td><td>:g'
		echo "</tr></table>"
		;;
	uptime)
		IP=`grep -w $FILE /root/.ssh/ip|awk '{print $1}'`
		echo "$FILE($IP)<br>"
		ssh -i /root/.ssh/53kf-server.ssh $IP "uptime" > $LOAD
		echo "<table border=5><tr><td>系统时间</td><td>运行时长</td><td>系统用户</td><td>系统负载</td><td>1分钟</td><td>5分钟</td><td>15分钟</td></tr>"
	sed -r -e 's:up:</td><td>:' -e 's@(.*)<td>(.*),(.*)user,(.*)@\1<td>\2</td><td>\3user</td><td>\4</td>@' -e 's@average:@average</td><td>@' -e 's@days,@days +@' -e 's:,:</td><td>:g' -e 's:(.*):<tr><td>\1</tr>:' $LOAD
		echo "</tr></table>"
		;;
	stoplist)
		IP=`grep -w $FILE /root/.ssh/ip|awk '{print $1}'`
		echo "$FILE($IP)<br>"
		rm -rf $BADUSER 
		for i in "$(ssh -i /root/.ssh/53kf-server.ssh -n $IP "awk -F'->' '!/{/{print \$1\"@\"\$2}' /opt/nginx/conf/stoplist|sed -r 's:[\"#]:@:g'")";do echo "$i" >> $BADUSER;done
		echo "<table border=5><tr><td>账号</td><td>拦截时间</td><td>理由</td><td>封锁时间(秒为单位)</td></tr>"
		while read LINE;do
			user=`echo $LINE|awk -F@ '{print $1}'`
			time=`echo $LINE|awk -F@ '{print $2}'`
			reason=`echo $LINE|awk -F@ '{print $3}'`
			locktime=`echo $LINE|awk -F@ '{print $6}'`
			echo "<tr><td>$user</td><td>$time</td><td>$reason</td><td>$locktime</td></tr>";
		done < $BADUSER
		echo "</tr></table>"	
		;;
	blacklist)
		IP=`grep -w $FILE /root/.ssh/ip|awk '{print $1}'`
		echo "$FILE($IP)<br>"
		rm -rf $BLACK 
		for i in $(ssh -i /root/.ssh/53kf-server.ssh -n $IP "awk '{print \$1}' /opt/nginx/conf/blacklist");do grep $i /tmp/big_pv.log|head -3 >> $BLACK;done
		echo "<table border=5><tr><td>账号</td><td>流量</td><td>PV</td><td>拦截时间</td></tr>"
		while read LINE;do
			user=`echo $LINE|awk '{print $1}'`
			band=`echo $LINE|awk '{print $2}'`
			pv=`echo $LINE|awk '{print $3}'`
			time=`echo $LINE|awk '{print $7" "$8" "$9" "$10" "$11" "$12}'`
			echo "<tr><td>$user</td><td>$band</td><td>$pv</td><td>$time</td></tr>";
		done < $BLACK
		echo "</tr></table>"
		;;
	blackip)
		H=`echo $FILE|cut -d# -f1`
		BIP=`echo $FILE|cut -d# -f2`
		IP=`grep -w $H /root/.ssh/ip|awk '{print $1}'`
		echo "$IP($H)<br>"
		echo "<br>----------------------------------<br>"
		IP=$(ssh -i /root/.ssh/53kf-server.ssh -n $IP "sed -n \"/$BIP/p\" /etc/bad_ip")
		if [ -z "$IP" ];then
			echo "$BIP 不在黑名单内"
		else
			echo "$IP <a href=index.php?bip=$IP&blackip=$H&opt=del>解除此IP</a>"
		fi
		echo "<br>----------------------------------<br>"
		;;		
	delip)
		H=`echo $FILE|cut -d# -f1`
		BIP=`echo $FILE|cut -d# -f2`
		IP=`grep -w $H /root/.ssh/ip|awk '{print $1}'`
		echo "$IP($H)<br>"
		echo "<br>----------------------------------<br>"
		ssh -i /root/.ssh/53kf-server.ssh -n $IP "del_ip.sh $BIP"
		echo "<br>----------------------------------<br>"
		;;			
esac
