#!/bin/bash

if [ "$(id -u)" != "0" ]; then
  echo "Please run this script as root." 1>&2
  exit 1
fi

# Based on confirmation code from http://stackoverflow.com/a/3232082
echo -e "\nWARNING: Nepenthes' remote installation is a bit messy."
echo -e "Consider installing it only on single-purpose VMs.\n"
echo "You are currently in ($(pwd)) on ($(hostname))."
read -r -p \
  "Do you really want to install the Nepenthes remote worker? [y/N] " response
response=${response,,}    # tolower
if [[ $response =~ ^(yes|y)$ ]]; then
  echo "Continuing..."
else
  echo "Exiting."
  exit 1
fi

echo -e "\n[*] Checking for Redis..."
echo -en "PING\r\n" | nc -w 5 127.0.0.1 6379 | grep -q PONG
if [ $? -ne 0 ]; then
  echo "Couldn't detect Redis on localhost." \
    "Try SSHing to this worker like this:"
  echo "ssh -R 127.0.0.1:6379:127.0.0.1:6379 [user]@[host]"
  exit 1
fi
echo "Redis works."

PACKAGES="git tmux build-essential libfontconfig1 ruby1.9.1 ruby1.9.1-dev \
  libsqlite3-dev libxslt1-dev nmap nikto"

UBUNTU_VERSION=`lsb_release -r -s`

if [ $UBUNTU_VERSION \< "12.10" ]; then
  echo -e "\n[*] Using Ubuntu < 12.10, downloading PhantomJS separately."
  wget -O phantomjs.tar.bz2 \
    https://phantomjs.googlecode.com/files/phantomjs-1.9.2-linux-i686.tar.bz2
  sha1sum phantomjs.tar.bz2 | grep -q 9ead5dd275f79eaced61ce63dbeca58be4d7f090
  if [ $? -ne 0 ]; then
    echo "Unexpected PhantomJS SHA-1 hash. Please try again."
    exit 1
  fi
  echo -e "\n[*] Extracting PhantomJS..."
  tar xjf phantomjs.tar.bz2
  echo -e "\n[*] Installing PhantomJS..."
  cp phantomjs-*/bin/phantomjs /bin/
else
  echo -e "\n[*] Using Ubuntu >= 12.10, using the repository's PhantomJS."
  PACKAGES="$PACKAGES phantomjs"
fi

echo -e "\n[*] Checking multiverse availability"
grep -q '^\s*deb.*multiverse' /etc/apt/sources.list
if [ $? -ne 0 ]; then
  echo "No multiverse, backing up /etc/apt/sources.list and adding it."
  cp /etc/apt/sources.list /etc/apt/sources.list.pre-nepenthes
  echo "deb http://archive.ubuntu.com/ubuntu `lsb_release -c -s` multiverse" \
    >> /etc/apt.sources.list
  echo -n "deb http://archive.ubuntu.com/ubuntu `lsb_release -c -s`-updates" \
    >> /etc/apt.sources.list
  echo " multiverse" >> /etc/apt/sources.list
else
  echo "Multiverse appears to be enabled."
fi

echo -e "\n[*] Updating Ubuntu package information cache"
apt-get update

echo -e "\n[*] Installing packages ($PACKAGES)"
apt-get install -y $PACKAGES

if [ -e nepenthes ]; then
  echo -e "\n[*] Removing old nepenthes."
  rm -Rf nepenthes
fi

echo -e "\n[*] Fetching Nepenthes"
git clone https://github.com/aschmitz/nepenthes.git
cd nepenthes

echo -e "\n[*] Tidying Nepenthes for remote work"
cp config/database.yml.example config/database.yml
chmod 0777 log
cp config/auth.yml.example config/auth.yml

echo -e "\n[*] Installing Bundler"
gem install --no-rdoc --no-ri bundler

echo -e "\n[*] Installing Nepenthes' required gems"
bundle install --without local
