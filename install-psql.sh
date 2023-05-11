#!/bin/bash

# Prompt user for the VBSF IP Address
ip_valid=false
while[$ip_valid == false]
do
  read -p "Enter the IP address of the Veeam Backup for SF server: " vbsf_ip
  if [[ $vbsf_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ip_valid=true
  else
    echo "$vbsf_ip is not a valid IP address. Please try again."
  fi
done

# Update package information before installation
echo 'Updating package information...'
apt-get update

# Install PostgreSQL
echo 'Installing PostgreSQL...'
apt install postgresql -y

# Check installed version
PSQL_MAJOR_VER = postgres -V | egrep -o '[0-9]{1,}'

# Enable remote connections
echo 'Editing postgresql.conf for remote connections...'
sed -i 's/#listen_addresses=\'localhost\'/listen_addresses=\'*\'/' /etc/postgresql/$PSQL_MAJOR_VER/main/postgresql.conf 

echo 'Editing pg_hba.conf for remote connections...'
sed -i 's/host    all             all             127.0.0.1/32            md5/host    all             all             '$vbsf_ip'/32            md5/' /etc/postgresql/$PSQL_MAJOR_VER/main/postgresql.conf
