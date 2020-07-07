# OnePunchScan
![](/one_punch_man_ok.jpg)

**OnePunchScan** is a recon tool which automates basic service enumeration using nmap and masscan. It is intended as a time-saving tool for use in remote network environments like HackTheBox or OSCP.

This is a very simple to read bash script with **NO AUTOMATED EXPLOITATION!!!**

## Origin
OnePunchScan was inspired by Superkojiman's [onetwopunch](https://github.com/superkojiman/onetwopunch). I wanted to create a simple script that could *quickly* run the standard enumeration I do for every machine and export it to a decent looking report. While avoiding network errors introduced by VPNs. If you are looking for something more complex I would recommend Tib3rius' [AutoRecon](https://github.com/Tib3rius/AutoRecon).

## Requirements
```
 masscan 1.0.6+
 nmap
```
## Installation
```
cd /opt
git clone https://github.com/Carp704/OnePunchScan.git
cd OnePunchScan
chmod +x OnePunchScan.sh
```
## Usage
```
onepunchscan.sh -t target [-p tcp/udp/all] [-i interface] [-o "NMAP options"] [-h]
    -h: Help
    -i: Network interface (Defaults to tun0)
    -p: Protocol (Defaults to tcp)
    -t: Target IP or Range
    -o: Specify NMAP options (-Pn, -sV, --script safe, etc.)
```

**Example:**
```
sudo onepunchscan.sh -t 192.168.0.100 -p all -i eth0 -o "-sV -sC"
```
### Liability
Carp_704 will not be liable for damages or losses arising from your use or inability to use the tool or otherwise arising under this agreement. 
You are responsible for how you use this tool. 


