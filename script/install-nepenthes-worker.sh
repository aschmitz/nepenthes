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

PACKAGES="git tmux build-essential libfontconfig1 libsqlite3-dev libxslt1-dev \
  nmap nikto openssh-server zlib1g-dev redis-tools"

UBUNTU_VERSION=`lsb_release -r -s`

if [ $UBUNTU_VERSION \< "14.04" ]; then
  echo -e "\n[*] Using Ubuntu < 14.04, forcing Ruby 1.9.1"
  PACKAGES="$PACKAGES ruby1.9.1 ruby1.9.1-dev"
else
  echo -e "\n[*] Using Ubuntu >= 14.04, using default Ruby"
  PACKAGES="$PACKAGES ruby ruby-dev"
fi

echo -e "\n[*] Downloading PhantomJS separately."
arch=`uname -m`
if [[ $arch == "x86_64" ]]; then
  phantomjshash=86dd9a4bf4aee45f1a84c9f61cf1947c1d6dce9b9e8d2a907105da7852460d2f
else
  phantomjshash=80e03cfeb22cc4dfe4e73b68ab81c9fdd7c78968cfd5358e6af33960464f15e3
fi
# Yes, this isn't an official source, but we're checking the hashes.
# Bitbucket (the current official source) seems to block automatic downloads.
wget -O phantomjs.tar.bz2 \
   https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-$arch.tar.bz2
  #https://github.com/paladox/phantomjs/releases/download/2.1.7/phantomjs-2.1.1-linux-$arch.tar.bz2
sha256sum phantomjs.tar.bz2 | grep -q $phantomjshash
if [ $? -ne 0 ]; then
  echo "Unexpected PhantomJS SHA-1 hash. Please try again."
  exit 1
fi
echo -e "\n[*] Extracting PhantomJS..."
tar xjf phantomjs.tar.bz2
echo -e "\n[*] Installing PhantomJS..."
cp phantomjs-*/bin/phantomjs /bin/

echo -e "\n[*] Checking multiverse availability"
grep -q '^\s*deb.*multiverse' /etc/apt/sources.list
if [ $? -ne 0 ]; then
  echo "No multiverse, backing up /etc/apt/sources.list and adding it."
  cp /etc/apt/sources.list /etc/apt/sources.list.pre-nepenthes
  echo "deb http://archive.ubuntu.com/ubuntu `lsb_release -c -s`" \
    "multiverse" >> /etc/apt/sources.list
  echo -n "deb http://archive.ubuntu.com/ubuntu `lsb_release -c -s`-updates" \
    "multiverse" >> /etc/apt/sources.list
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
gem install --no-rdoc --no-ri bundler -v 1.16.0

echo -e "\n[*] Installing Nepenthes' required gems"
bundle _1.16.0_ install --without local

echo -e "\n[*] Dropping Nepenthes worker scripts in ~/"
ln -s `pwd`/script/*worker*.sh ../
chmod +x script/*worker*.sh

echo -e "\n[*] Run ./start-nepenthes-worker.sh to begin."
