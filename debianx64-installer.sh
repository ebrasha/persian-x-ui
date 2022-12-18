#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}mistake：${plain} This script must be run with the root user！\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}System version not detected, please contact the script author! Prof.Shafiei@gmail.com ${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
    arch="amd64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
    arch="arm64"
elif [[ $arch == "s390x" ]]; then
    arch="s390x"
else
    arch="amd64"
    echo -e "${red}Detect schema failed, use default schema:${arch}${plain}"
fi

echo "Architecture: ${arch}"

if [ $(getconf WORD_BIT) != '32' ] && [ $(getconf LONG_BIT) != '64' ]; then
    echo "This software does not support 32-bit system (x86), please use 64-bit system (x86_64), if the detection is wrong, please contact the:  Prof.Shafiei@Gmail.com"
    exit -1
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}please use CentOS 7 or later system！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}please use Ubuntu 16 or later system！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}please use Debian 8 or later system！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install wget curl tar zip unzip -y
    else
        apt install wget curl tar zip unzip  -y
    fi
}

#This function will be called when user installed x-ui out of sercurity
config_after_install() {
    echo -e "${yellow}For security reasons, port and account passwords must be changed after installation/update${plain}"
    read -p "confirm whether to continue?[y/n]": config_confirm
    if [[ x"${config_confirm}" == x"y" || x"${config_confirm}" == x"Y" ]]; then
        read -p "Please set your account name:" config_account
        echo -e "${yellow}Your account name will be set to:${config_account}${plain}"
        read -p "Please set your account password:" config_password
        echo -e "${yellow}Your account password will be set to:${config_password}${plain}"
        read -p "Please set the panel access port:" config_port
        echo -e "${yellow}Your panel access port will be set to:${config_port}${plain}"
        echo -e "${yellow}Confirm the setting, setting${plain}"
        /usr/local/x-ui-persian/x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}The account password is set${plain}"
        /usr/local/x-ui-persian/x-ui setting -port ${config_port}
        echo -e "${yellow}Panel port setting completed${plain}"
    else
        echo -e "${red}Canceled, all setting items are default settings, please modify in time${plain}"
    fi
}

install_x-ui() {
    systemctl stop x-ui
    systemctl stop x-ui-persian
    x-ui-persian stop
    rm -f /etc/systemd/system/x-ui.service
    rm -rf /usr/local/x-ui-persian/
    rm -rf /usr/local/x-ui/

    cd /usr/local/
    rm -f x-ui-persian-linux-debian-amd64.zip
     if [[ -e /usr/local/x-ui-persian/ ]]; then
        rm /usr/local/x-ui-persian/ -rf
    fi
    url_zip_file="https://raw.githubusercontent.com/abdal-security-group/persian-x-ui/main/x-ui-persian-linux-debian-amd64.zip"
    wget -N --no-check-certificate -O /usr/local/x-ui-persian-linux-debian-amd64.zip  ${url_zip_file}
    unzip x-ui-persian-linux-debian-amd64.zip
    rm  -f  x-ui-persian-linux-debian-amd64.zip
    cd x-ui-persian
    chmod +x x-ui bin/xray-linux-amd64
    cp -f x-ui.service /etc/systemd/system/
    chmod +x /usr/local/x-ui-persian/x-ui-persian.sh
    cp -f   /usr/local/x-ui-persian/x-ui-persian.sh   /usr/bin/x-ui-persian
    chmod +x /usr/bin/x-ui-persian

    /usr/local/x-ui-persian/x-ui setting -username  ebrasha  -password ebrasha
    /usr/local/x-ui-persian/x-ui setting -port 1366

    echo "# Created By persian-x-ui : start" >> /etc/sysctl.conf
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
    echo "# Created By persian-x-ui : End" >> /etc/sysctl.conf
    sysctl -p
    clear
    
    config_after_install
    
    
    echo -e "If it is a fresh installation, the default web port is ${green}1366${plain}，The default username and password are ${green}ebrasha${plain}"
    echo -e "Please make sure that this port is not occupied by other programs，${yellow}And make sure port 1366 is released${plain}"
        echo -e "If you want to modify 1366 to other ports, enter the x-ui command to modify, and also make sure that the port you modify is also allowed"
    echo -e ""
    echo -e "If updating the panel, access the panel as you did before"
    echo -e ""
    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    
    echo -e "${green}persian-x-ui installation is complete, the panel is activated, "
    echo -e ""
    echo -e "x-ui How to use the management script: "
    echo -e "****** Farsi development By Ebrahim Shafiei ******"
    echo -e ""
    echo -e "----------------------------------------------"
    echo -e "x-ui-persian              - Show admin menu (more features)"
    echo -e "x-ui-persian start        - Start the x-ui-persian panel"
    echo -e "x-ui-persian stop         - stop x-ui-persian panel"
    echo -e "x-ui-persian restart      - Restart the x-ui-persian panel"
    echo -e "x-ui-persian status       - View x-ui-persian status"
    echo -e "x-ui-persian enable       - Set x-ui-persian to start automatically at boot"
    echo -e "x-ui-persian disable      - cancel x-ui-persian autostart"
    echo -e "x-ui-persian log          - View x-ui-persian logs"
    echo -e "x-ui-persian v2-ui        - Migrate the v2-ui account data of this machine to x-ui-persian"
    echo -e "x-ui-persian update       - update x-ui-persian panel"
    echo -e "x-ui-persian install      - Install the x-ui-persian panel"
    echo -e "x-ui-persian uninstall    - Uninstall the x-ui-persian panel"
    echo -e "----------------------------------------------${plain}"




}

echo -e "${green}start installation${plain}"
install_base
install_x-ui $1
