#!/bin/bash
# perfect_dump.sh - infinitly close to master before crashing

dump_user=root
dump_pass=mysql56
dump_dir=/tmp
db_name=test

## stop the last mysqlbinlog
mysqlbinlog_pid=`pgrep mysqlbinlog`
if [ ${mysqlbinlog_pid} ];then
kill -9 ${mysqlbinlog_pid}
fi

## dump data on local slave
/usr/local/mysql/bin/mysqldump -u${dump_user} -p${dump_pass} -h127.0.0.1 --dump-slave=2 \
                               --include-master-host-port --single-transaction \
                               --routines --triggers --events --hex-blob \
                               --default-character-set=utf8 \
                               --databases ${db_name} >${dump_dir}/${db_name}.sql 2>/dev/null
## dump binlog from remote master
master_status=`grep -m1 -i "change master" ${db_name}.sql \
               |sed -e 's/,//g' -e 's/;//' -e "s/'//g" | awk '{print $5" "$6" "$7" "$8}'`
master_host=`echo ${master_status} |awk '{print $1}' |awk -F'=' '{print $2}'`
master_port=`echo ${master_status} |awk '{print $2}' |awk -F'=' '{print $2}'`
master_log_file=`echo ${master_status} |awk '{print $3}' |awk -F'=' '{print $2}'`
master_log_pos=`echo ${master_status} |awk '{print $4}' |awk -F'=' '{print $2}'`
/usr/local/mysql/bin/mysqlbinlog -u${dump_user} -p${dump_pass} -h${master_host} -P${master_port} \
                                 --start-position=${master_log_pos} --read-from-remote-server --raw \
                                 --stop-never --result-file=${dump_dir}/ \
                                 ${master_log_file} 2>/dev/null
