#!/bin/bash 

# About: Automate your initial (OSCP/HTB/etc.) scanning with nmap and masscan. 
# Inspired by: https://github.com/superkojiman/onetwopunch by superkojiman. 
# @carp_704

ESC="\e["
DEFAULT=$ESC"39m"
RED=$ESC"91m"
GREEN=$ESC"92m"
YELLOW=$ESC"93m"
BLUE=$ESC"94m"
PURPLE=$ESC"95m"
TEAL=$ESC"96m"


function banner {
echo -e '------------------------------------------------------------------------------------------------------------------------'
echo -e ' MMMMMMMMMMMMMMMMMMMMMMMMMMmy+////::::::::/odMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMm/        `:dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'
echo -e ' MMMMMMMMMMMMMMMMMMMMMMMNds++++///:::::::::::omMMMMMMMMMMMMMMMMMMMMMMMMMMMs`            oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMMNh+++///:::::::::::::::/dMMMMMMMMMMMMMMMMMMMMMMMMM+               oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMNy//////:/:::::::::::::::/dMMMMMMMMMMMMMMMMMMMMMMMo                 mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMd++++/////::::::::::::::::/mMMMMMMMMMMMMMMMMMMMMMh                  oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMN+///////:::::::::::::::::::yNMMMMMMMMMMMMMMMMMMMM:                  .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMmMMMMMMd++++++///:+ooooo+o:::+++++/+mMMMMMMMMMMMMMMMMMMMM`                   mMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMm++++++//://+++s/o:::/+/o:/+/mMMMMMMMMMMMMMMMMMMMm                    hMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMmss+////::+/.``--o::o+:`../+:mMMMMMMMMMMMMMMMMMMMd           OK       hMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMhsooy/////////////:::y://///::dMMMMMMMMMMMMMMMMMMMh                     dMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMsyoh+///////:::::::::+/:::::::dMMMMMMMMMMMMMMMMMMM+                     MMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMy/oy+///////::::::::::s:::::::dMMMMMMMMMMMMMMMMMMMy.                  -MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMmohsy///::::::::::::::/::::::/mMMMMMMMMMMMMMMMMMMMMy                  oMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMmsoo+///////::::::::::::::::oNMMMMMMMMMMMMMMMMMMMMN`                 mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMNmdm+/+/////::::::++/::::::yMMMMMMMMMMMMMMMMMMMMMM/                /MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMMMMMd+++///:::::::::::::::yNMMMMMMMMMMMMMMMMMMMMMMy               `mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMMMMMMd+/////:::::::::::::sNMMMMMMMMMMMMMMMMMMMMMMMN.             `yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMMMMMMMmy++//:::::::::::+hNMMMMMMMMMMMMMMMMMMMMMMMMMm+.         .+mMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMMMMMMMMNyoo+//::::::/ohNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNho/---/+ymMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM '
echo -e ' MMMMMMMMMMMMMMMMMMMMMMMMMMMMNyoosssoo+++++mNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM{@CARP_704}MMMMMMMMM '
echo -e ' ------------------------------------------------------------------------------------------------------------------------ '
}

function usage {
    echo "Usage: $0 -t target [-p tcp/udp/all] [-i interface] [-o "NMAP options"] [-h]"
    echo "       -h: Help"
    echo "       -i: Network interface (Defaults to tun0)"
    echo "       -p: Protocol (Defaults to tcp)"
    echo "       -t: Target IP or Range"
    echo "       -o: Specify NMAP options (-Pn, -sV, --script safe, etc.)"

}

banner

# validation

if [[ ! $(id -u) == 0 ]]; then
    echo -e "${RED}[!]${DEFAULT} This script must be run as root"
    exit 1
fi

if [[ -z $(which nmap) ]]; then
    echo -e "${RED}[!]${DEFAULT} Unable to find nmap. Install it and make sure it's in your PATH."
    exit 1
fi

if [[ -z $(which masscan) ]]; then
    echo -e "${RED}[!]${DEFAULT} Unable to find masscan. Install it and make sure it's in your PATH."
    echo -e "${YELLOW}[-]${DEFAULT} sudo apt-get install git gcc make libpcap-dev "
    echo -e "${YELLOW}[-]${DEFAULT} git clone https://github.com/robertdavidgraham/masscan "
    echo -e "${YELLOW}[-]${DEFAULT} cd masscan "
    echo -e "${YELLOW}[-]${DEFAULT} make "
    exit 1
fi

if [[ -z $1 ]]; then
    usage
    exit 0
fi

# default options
proto="tcp"
iface="tun0"

while getopts "p:i:t:o:h" OPT; do
    case $OPT in
        p) proto=${OPTARG};;
        i) iface=${OPTARG};;
        t) targets=${OPTARG};;
	o) options=${OPTARG};;
        h) usage; exit 0;;
        *) usage; exit 0;;
    esac
done

if [[ -z $targets ]]; then
    echo "${RED}[!]${DEFAULT} No target(s) provided"
    usage
    exit 1
fi

if [[ ${proto} != "tcp" && ${proto} != "udp" && ${proto} != "all" ]]; then
    echo "${RED}[!]${DEFAULT} Unsupported protocol"
    usage
    exit 1
fi

echo -e "${BLUE}[+]${DEFAULT} Protocol : ${proto}"
echo -e "${BLUE}[+]${DEFAULT} Interface : ${iface}"
echo -e "${BLUE}[+]${DEFAULT} Targets : ${targets}"
echo -e "${BLUE}[+]${DEFAULT} NMAP Options : ${options}"

# masscan version check (pre-1.0.6 causes errors)
installed=$(masscan --version | grep version | head -n 1 | cut -d" " -f 3)
current=1.0.6
if [[  $installed > $current || $installed = $current ]]; then
	:
else
	echo -n "${RED}[!]${DEFAULT} Please update your masscan to version 1.0.6 or greater."
fi


# backup old scans
log_dir="$(pwd)/onepunchscan"
mkdir -p "${log_dir}/backup/"
if [[ -d "${log_dir}/ndir/" ]]; then 
    mv "${log_dir}/ndir/" "${log_dir}/backup/ndir-$(date "+%Y%m%d-%H%M%S")/"
fi
if [[ -d "${log_dir}/udir/" ]]; then 
    mv "${log_dir}/udir/" "${log_dir}/backup/udir-$(date "+%Y%m%d-%H%M%S")/"
fi 

rm -rf "${log_dir}/ndir/"
mkdir -p "${log_dir}/ndir/"
rm -rf "${log_dir}/udir/"
mkdir -p "${log_dir}/udir/"

# locate install directory

if [[ ! -z $(locate OnePunchScan) ]]; then  
	tooldir=$(locate OnePunchScan | head -n 1)
else
	echo -e "${YELLOW}[-]${DEFAULT}Could not locate OnePunchScan... updating search database"
	updateb
	if [[ ! -z $(locate OnePunchScan) ]]; then
	    tooldir=$(locate OnePunchScan | head -n 1)
        else
	    echo -e "${RED}[-]${DEFAULT}Could not locate OnePunchScan..."
        fi
fi

# create target list
target_list=${log_dir}/ndir/target_list
nmap -sL ${targets} | awk '/Nmap scan report/{print $NF}' | tr -d [\(,\)] > ${target_list}

while read ip; do
    log_ip=$(echo ${ip} | sed 's/\//-/g')
    echo -e "${BLUE}[+]${DEFAULT} Scanning $ip for $proto ports..."

    # masscan identifies all open TCP ports
    if [[ $proto == "tcp" || $proto == "all" ]]; then 
        echo -e "${BLUE}[+]${DEFAULT} Obtaining all open TCP ports..."
        echo -e "${BLUE}[+]${DEFAULT} masscan -p0-65535 --rate=1000 --wait 5 -e tun0 -oG ${log_dir}/udir/${log_ip}-tcp.txt ${ip}"
        masscan -p0-65535 --rate=2000 --wait 5 -e tun0 -oG ${log_dir}/udir/${log_ip}-tcp.txt ${ip}
        ports=$(cat "${log_dir}/udir/${log_ip}-tcp.txt" | grep open | cut -d" " -f5 | cut -d"/" -f 1 | tr '\n' ',')
        if [[ ! -z $ports ]]; then
	    if [[ -z $options ]]; then 
                # nmap scans and creates a report
                echo -e "${GREEN}[*]${DEFAULT} TCP ports for nmap to scan: $ports"
	        echo -e "${BLUE}[+]${DEFAULT} nmap -Pn -sV -sC --min-rate 5000 -p${ports} -n -e ${iface} --stylesheet ${tooldir}/nmap-bootstrap.xsl -T4 -oX ${log_dir}/ndir/${log_ip}/tcp.xml ${ip}"
                mkdir -p ${log_dir}/ndir/${log_ip} 2>/dev/null
                nmap -Pn -sV -sC --min-rate 5000 -p${ports} -n -e ${iface} --stylesheet ${tooldir}/nmap-bootstrap.xsl -T4 -oX ${log_dir}/ndir/${log_ip}/tcp.xml ${ip}
                xsltproc -o ${log_dir}/ndir/${log_ip}/tcp.html ${tooldir}/nmap-bootstrap.xsl ${log_dir}/ndir/${log_ip}/tcp.xml
            else
		echo -e "${GREEN}[*]${DEFAULT} TCP ports for nmap to scan: $ports"
                echo -e "${BLUE}[+]${DEFAULT} nmap -Pn ${options} --min-rate 5000 -p${ports} -n -e ${iface} --stylesheet ${tooldir}/nmap-bootstrap.xsl -T4 -oX ${log_dir}/ndir/${log_ip}/tcp.xml ${ip}"
                mkdir -p ${log_dir}/ndir/${log_ip} 2>/dev/null
                nmap -Pn ${options} --min-rate 5000 -p${ports} -n -e ${iface} --stylesheet ${tooldir}/nmap-bootstrap.xsl -T4 -oX ${log_dir}/ndir/${log_ip}/tcp.xml ${ip}
                xsltproc -o ${log_dir}/ndir/${log_ip}/tcp.html ${tooldir}/nmap-bootstrap.xsl ${log_dir}/ndir/${log_ip}/tcp.xml
            fi		
        else
            echo -e "${RED}[!]${DEFAULT} No TCP ports found"
        fi
    fi

    # Due to UDP errors on masscan nmap identifies all open UDP ports
    if [[ $proto == "udp" || $proto == "all" ]]; then  
        echo -e "${BLUE}[+]${DEFAULT} Obtaining all open UDP ports..."
        echo -e "${BLUE}[+]${DEFAULT} nmap -n -Pn -sU -p- -e ${iface} -oX "${log_dir}/udir/${log_ip}-udp.txt" ${ip}"
        nmap -n -Pn --min-rate 10000 -sU -T5 -p- -e ${iface} -oX "${log_dir}/udir/${log_ip}-udp.txt" ${ip}
        ports=$(cat ${log_dir}/udir/${log_ip}-udp.txt | grep open | grep -v count | cut -d'"' -f4)
        if [[ ! -z $ports ]]; then
            if [[ -z $options ]]; then
                # nmap scans and creates a report
                echo -e "${GREEN}[*]${DEFAULT} UDP ports for nmap to scan: $ports"
                echo -e "${BLUE}[+]${DEFAULT} nmap -Pn -sV -sU -sC -p${ports} -n -e ${iface} --stylesheet ${tooldir}/nmap-bootstrap.xsl -T4 -oX ${log_dir}/ndir/${log_ip}/udp.xml ${ip}"
	        mkdir -p ${log_dir}/ndir/${log_ip} 2>/dev/null
                nmap -Pn -sV -sU -sC -p${ports} -n -e ${iface} --stylesheet ${tooldir}/nmap-bootstrap.xsl -T4 -oX ${log_dir}/ndir/${log_ip}/udp.xml ${ip}
                xsltproc -o ${log_dir}/ndir/${log_ip}/udp.html ${tooldir}/nmap-bootstrap.xsl ${log_dir}/ndir/${log_ip}/udp.xml
            else 
                echo -e "${GREEN}[*]${DEFAULT} UDP ports for nmap to scan: $ports"
                echo -e "${BLUE}[+]${DEFAULT} nmap -Pn -sU ${options} --min-rate 5000 -p${ports} -n -e ${iface} --stylesheet $(pwd)/nmap-bootstrap.xsl -T4 -oX ${log_dir}/ndir/${log_ip}/udp.xml ${ip}"
	        mkdir -p ${log_dir}/ndir/${log_ip} 2>/dev/null
                nmap -Pn -sU ${options} --min-rate 5000 -p${ports} -n -e ${iface} --stylesheet ${tooldir}/nmap-bootstrap.xsl -T4 -oX ${log_dir}/ndir/${log_ip}/udp.xml ${ip}
                xsltproc -o ${log_dir}/ndir/${log_ip}/udp.html ${tooldir}/nmap-bootstrap.xsl ${log_dir}/ndir/${log_ip}/udp.xml
            fi
        else
            echo -e "${RED}[!]${DEFAULT} No UDP ports found"
        fi
    fi
    
done < ${target_list}

echo -e "${BLUE}[+]${DEFAULT} Scans completed"
echo -e "${BLUE}[+]${DEFAULT} Results saved to ${log_dir}"
