#! /usr/local/bin/bash
#首先获取当前的ip设置，在执行完ip的操作后会恢复为当前设置
inet_ip=`ifconfig $1 | awk '$0 ~ / *inet */ {print $2}'`
inet_netmask=`ifconfig $1 | awk '$0 ~ / *inet */ {print $4}'`
inet_broadcast=`ifconfig $1 | awk '$0 ~ / *inet */ {print $6}'`
#读取文件的内容并将ip,netmask,broadcast的地址读入相关数组中保存
temp=`wc -l $2`
declare -i i=0;
declare -i LineNumber=`echo $temp | awk '{print $1}'`
declare -i n;
while [ "$i" != "$LineNumber" ]
do
    n=$i+1
    ip_array[n]=`head -n $n $2 | tail -n 1 | awk '{print $1}'`
    netmask_array[n]=`head -n $n $2 | tail -n 1 | awk '{print $2}'`
    broadcast_array[n]=`head -n $n $2 | tail -n 1 | awk '{print $3}'`
    i=$i+1
done
#用ifconfig命令更改ip地址，然后进行投票工作，最后恢复主机从前的ip设置
i=0;
while [ "$i" != "$LineNumber" ]
do
    n=$i+1
    echo "ifconfig $1 inet ${ip_array[`echo $n`]} netmask ${netmask_array[`echo $n`]} broadcast ${broadcast_array[`echo $n`]}"
    ifconfig $1 inet ${ip_array[`echo $n`]} netmask ${netmask_array[`echo $n`]} broadcast ${broadcast_array[`echo $n`]}
    route add default 210.77.79.254
   
#在这里添加要执行操作的代码
    i=$i+1
done
#最后恢复为原来的设置
ifconfig $1 inet $inet_ip netmask $inet_netmask broadcast $inet_broadcast
route add default 210.77.68.25
