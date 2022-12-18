#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

confirm() {
  if [[ $# > 1 ]]; then
    echo && read -p "$1 [default $2]: " temp
    if [[ x"${temp}" == x"" ]]; then
      temp=$2
    fi
  else
    read -p "$1 [y/n]: " temp
  fi
  if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
    return 0
  else
    return 1
  fi
}

uninstalling() {
  confirm "Are you sure you want to uninstall the panel, xray will also be uninstalled?" "n"
  if [[ $? != 0 ]]; then
    if [[ $# == 0 ]]; then
      echo "uninstalling canceled by user "
    fi
    return 0
  fi
  systemctl stop x-ui >/dev/null 2>&1
  systemctl disable x-ui >/dev/null 2>&1

  systemctl stop x-ui >/dev/null 2>&1
  systemctl stop x-ui-persian >/dev/null 2>&1
  x-ui-persian stop >/dev/null 2>&1

  rm /usr/bin/x-ui -f >/dev/null 2>&1
  rm /usr/bin/x-ui-persian -f >/dev/null 2>&1

  rm /etc/systemd/system/x-ui.service -f >/dev/null 2>&1
  systemctl daemon-reload >/dev/null 2>&1
  systemctl reset-failed >/dev/null 2>&1
  rm /etc/x-ui/ -rf >/dev/null 2>&1
  rm /usr/local/x-ui-persian/ -rf >/dev/null 2>&1

  rm -f /etc/systemd/system/x-ui.service >/dev/null 2>&1
  rm -rf /usr/local/x-ui-persian/ >/dev/null 2>&1
  rm -rf /usr/local/x-ui/ >/dev/null 2>&1
  rm -rf /etc/x-ui/x-ui.db >/dev/null 2>&1

  echo ""
  echo -e "${red}---------------------------------${plain}"
  echo -e "${green}The uninstallation is successful.${plain}"
  echo -e "${yellow}If there is a problem with the program, let us know: Prof.Shafiei@Gmail.com${plain}"
  echo -e "${red}---------------------------------${plain}"

  echo ""

}

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}mistake：${plain} This script must be run with the root user！\n" && exit 1
if [[ ! -d "/usr/local/x-ui-persian/" ]]; then
  echo -e "${red}Error: Cannot remove x-ui-Persian, because it has not been set up on this server.${plain}"
else
  uninstalling
fi
