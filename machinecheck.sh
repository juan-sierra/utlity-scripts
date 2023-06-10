#!/bin/bash
# bash version 5.0.3(1)-release
#========================================================================
# S L O W F R A M E C H E C K
#========================================================================
# SYNOPSIS
#       ./slowframecheck ${IP} ${OPTION}
#
# DESCRIPTION
#      Slow Frame Check - Bash Script
#      https://confluence.unity3d.com/x/Fh0UCw
#
# OPTIONS
#      Default is running all commands
#       -h, --help HELP!!!
#       -d  Checking dmsge Only
#       -f  Checking Frequnecy Only
#       -n  Checking Netstat Only
#       -t  Checking Turbo Only
#       -T  Checking Temperature Only
#       -C  Checking C-State Only
#       -y  Checking Hyperthreading Only
#========================================================================
# IMPLEMENTATION
#-    version         Slowframecheck 1.2.6
#-    code            Bash Script
#-    author          Henry Lee - Team Korea - DSE
#-    copyright       Copyright (c) Unity Multiplay DSE Team
#-    contributor     Zoey P.|Juan G.|Jay J.|Nash I.|DK L.|Travis A.
#========================================================================
# History
#    2022-04-02 Deployed by Henry Lee
#    2022-06-23 Henry Lee to hand over the script to Zoey P and Jay J
#               Contact zoey.park@unity3d.com and jay.jin@unity3d.com
#               for editing the script.
#========================================================================
# S L O W F R A M E C H E C K
#========================================================================

##Setting variable=======================================================
SSH_ARGS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
SH="ssh $SSH_ARGS"
SH_HOST="root@${1}"
IP=${1}
Green='\033[0;32m'
Yellow='\033[1;33m'
Red='\033[1;31m'
NC='\033[0m'
opt=${2}
day=$(date | awk '{print $3}')
month=$(date | awk '{print $2}')
host=$(who am i | awk '{print $1}')
dir="/home/${host}"
OK="${Green} ============= [ OK ]${NC}"
BAD="${Red}  ============= [ BAD ]${NC}"

#Main condition==========================================================

# Consistent space for output summary: https://askubuntu.com/questions/923396/how-to-format-output-of-script-to-have-equal-number-of-spaces

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "[I] LOOK BELOW FOR HOW TO USE"
        echo "./machinecheck IP_Adress Option"
        echo " "
        echo "Default is running all commands"
        echo " -h, --help HELP!!!"
        echo " "
        echo " -d  Checking dmsge Only"
        echo " -f  Checking Frequnecy Only"
        echo " -n  Checking Netstat Only"
        echo " -t  Checking Turbo Only"
        echo " -T  Checking Temperature Only"
        echo " -C  Checking C-State Only"
        echo " -y  Checking Hyperthreading Only"
        echo " -v  To output error messages"
        echo " "
        exit 255
fi

if [[ ! "$IP" =~ ((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])$ ]]; then
        #	(([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.([01]{,1}[0-9]{1,2}|2[0-4][0-9]|25[0-5]))$ ]]; then
        printf $Red"Please insert correct IP format 8.8.8.8"$NC
        echo " "
        printf $Yellow"Please type -h or --help to see how it works"$NC
        echo " "
        exit 255
fi

#Main Functions===========================================================

#Check CPU Frequency
fre_check() {
        count=$($SH $SH_HOST "cat /proc/cpuinfo | grep 'physical id' | sort -u |wc -l")
        if [ $count -gt 1 ]; then
                freq=$($SH $SH_HOST "cpupower monitor -m Mperf | awk 'NR>2 {sum += "'$6'"; count++} END {printf "'"'"%.0f"'"'", sum / count}'")
        else
                freq=$($SH $SH_HOST "cpupower monitor -m Mperf | awk 'NR>2 {sum += "'$4'"; count++} END {printf "'"'"%.0f"'"'", sum / count}'")
        fi
        if [ "$freq" = "" ]; then
                echo "unknown frequency"
        else
                val=$(awk 'BEGIN{print ('"$freq"' <= 3000)}')
                if [ $val -eq 1 ]; then
                        printf "CPU Frequency: Low\n"
                        printf "Frequency: ${freq} ${BAD}"
                        status="1"
                else
                        printf "CPU Frequency: Normal\n"
                        printf "Frequency: ${freq} ${OK}"
                        status="0"
                fi
        fi
}

#Check Temp
temp_check() {
        get_temp=$($SH $SH_HOST "sensors coretemp-isa-0000 | grep "+" | cut -d ":" -f2 ")
        sort_temp=$(echo "$get_temp" | awk '{print $1}' | cut -d "." -f1)
        printf $Yellow
        echo $sort_temp
        printf $NC
}

#Check CPU Type
cpu_check() {
        cpu=$($SH $SH_HOST "cat /proc/cpuinfo |grep 'model name' | head -n 1 | awk -F: '{print "'$2'"}'")
        if [ "$cpu" = "" ]; then
                echo "unknown cpu model"
        else
                echo "cpu :${cpu}"
        fi
        if [ 1 -ne $(echo $cpu | grep -cE '(E3|E-)') ]; then
                perf_issue "unexpected cpu ($cpu)!"
        fi
}

#Check dmesg
dmsg1_check() {
        # $SH = SSH
        ## $SH_HOST = root@whateverIP
        dmsg1=$($SH $SH_HOST "dmesg -l err -T")
        if [ -z "$dmsg1" ]; then
                #printf "[${Green}No Error dmesg -l err${NC}]"
                check1=$(echo " " >/dev/null)
        else
                echo " "
                printf $Yellow
                # echo "$dmsg1"
                printf $NC
        fi
}

dmsg2_check() {
        dmsg2=$($SH $SH_HOST "dmesg | grep MC0 -T")
        if [ -z "$dmsg2" ]; then
                printf "No Error dmesg ${OK}"
                check2=$(echo " ")
        else
                printf $Yellow
                sortdmsg2=$(echo "$dmsg2" | grep -v 'Giving out device')
                if [ -z "$sortdmsg2" ]; then
                        #printf "[${Green}No Error dmesg | grep MC0${NC}]"
                        echo " "
                        printf "Dmesg: no errors ${OK}\n"
                else
                        echo " "
                        # echo "dmesg | grep MC0"
                        echo "$sortdmsg2"
                fi
        fi
}

dmsg3_check() {
        dmsg3=$($SH $SH_HOST "dmesg -T | grep error")
        if [ -z "$dmsg3" ]; then
                #printf "[${Green}No Error dmesg | grep error${NC}]"
                check3=$(echo " " >/dev/null)
        else
                sortdmsg3=$(echo "$dmsg3" | grep -v 'Enabling Firmware First' | grep -v 're-mounted')
                if [ -z "$sortdmsg3" ]; then
                        #printf "[${Green}No Error dmesg | grep error${NC}]"
                        echo " " >/dev/null
                        printf $NC
                else
                        echo " "
                        echo "dmesg | grep error"
                        printf $Yellow
                        echo "$sortdmsg3\n"
                        printf $NC
                fi
        fi
}

#Check Network Tran
net1_check() {
        printf $NC
        net1=$($SH $SH_HOST "netstat -s | grep bad")
        if [ -z "$net1" ]; then
                echo " "
                printf "Netstat: No Error ${OK}\n"
        else
                printf "Netstat: Errors ${BAD}\n"
                printf $Red
                echo $net1
                printf $NC
        fi
}

net2_check() {
        seg_ret=$($SH $SH_HOST "netstat -s | grep 'segments retr' | awk '{print $1}'")
        seg_sout=$($SH $SH_HOST "netstat -s | grep 'segments sent out' | awk '{print $1}'")
        #Calculate seg_ret / set_sout
        sort1=$(echo $seg_ret | awk '{print $1}')
        sort2=$(echo $seg_sout | awk '{print $1}')
        outcal=$(echo "scale=4; $sort1/$sort2" | bc -l)
        echo " "
        printf "${IP} Segment Retransmitted rate $sort1/$sort2=${Yellow}[${outcal}]${NC} - if above 0.1 raise it to DC"
        echo " "
        echo " "
}

#Turbo Mode Check
turbo_check() {
        cores=$(cat /proc/cpuinfo | grep processor | awk '{print $3}')
        state=$(for core in $cores; do
                turb=$($SH $SH_HOST "rdmsr -p${core} 0x1a0 -f 38:38 2> /dev/null")
                if [ ! $? == 0 ]; then
                        apt=$($SH $SH_HOST "apt install msr-tools -y 2> /dev/null")
                        turb=$($SH $SH_HOST "rdmsr -p${core} 0x1a0 -f 38:38")
                fi
                if [ "$turb" == 1 ]; then
                        echo "1"
                else
                        echo "0 "
                fi
        done 2>/dev/null)
        if [[ "$state" == *"1"* ]]; then
                printf "Turbo Mode: NOT Enabled ${BAD}"
                echo " "
                echo " "
        else
                printf "Turbo Mode: Enabled ${OK}"
                echo " "
                echo " "
        fi
}

#C-state Check
c_state_check() {
        c_gov=$($SH $SH_HOST "cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
        c_state=$($SH $SH_HOST "cat /sys/module/intel_idle/parameters/max_cstate")
        if [ "$c_state" == 0 ]; then
                printf "C-State: Disabled ${OK}"
                echo " "
                echo " "
        else
                printf "C-State: Enabled - Must be Disabled ${BAD}"
                echo " "
                echo " "
        fi

}

#Hyper Threading Check
hyper_thread_check() {
        thread=$($SH $SH_HOST "dmidecode -t processor | grep Count")
        core_count=$(echo "$thread" | grep 'Core Count' | awk '{print $3}')
        thread_count=$(echo "$thread" | grep 'Thread Count' | awk '{print $3}')
        if [ "$core_count" == "$thread_count" ]; then
                printf "Hyper Threading: Disabled ${BAD}"
                echo " "
                echo " "
        else
                printf "Hyper Threading Enabled ${OK}"
                echo " "
        fi

}

#Options ================================================================================
#Default is running all commands
if [ -z "$opt" ]; then
        echo "[ ${IP} ]"
        fre_check
        if [ $status -eq 0 ]; then
                echo " "
                dmsg1_check
                dmsg2_check
                dmsg3_check
                net1_check
                net2_check
                turbo_check
                c_state_check
                echo " "
        else
                cpu_check
                dmsg1_check
                dmsg2_check
                dmsg3_check
                net1_check
                net2_check
                turbo_check
                c_state_check
                echo " "
        fi
fi

#Running Frequency Only Option
if [ "$opt" == "-f" ]; then
        fre_check
        if [ $status -eq 0 ]; then
                echo " "
        else
                cpu_check
                echo " "
        fi
fi

if [ "$opt" == "-d" ]; then
        echo "[ ${IP} ]"
        dmsg1_check
        dmsg2_check
        dmsg3_check
        echo " "
fi

if [ "$opt" == "-n" ]; then
        echo "[ ${IP} ]"
        net1_check
        net2_check
        echo " "
fi

if [ "$opt" == "-t" ]; then
        turbo_check
fi

if [ "$opt" == "-T" ]; then
        echo "[ ${IP} ]"
        temp_check
fi

if [ "$opt" == "-C" ]; then
        c_state_check
fi

if [ "$opt" == "-y" ]; then
        echo "[ ${IP} ]"
        hyper_thread_check
        echo " "
fi

if [ "$opt" == "-v" ]; then
        c_state_check >>${dir}/C-state-${month}-${day}-validate &
fi

if [ "$opt" == "-vv" ]; then
        echo "[ ${IP} ]"
        echo "verbose output / summary "
fi
