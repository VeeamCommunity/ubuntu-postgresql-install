#!/bin/bash

# Prompt user for the VBSF IP Address
ip_valid=false
while[$ip_valid == false]
do
  read -p "Enter the IP address of the Veeam Backup for SF server: " vbsf_ip
  if [[ $vbsf_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ip_valid=true
  else
    printf "$vbsf_ip is not a valid IP address. Please try again."
  fi
done

# Update package information before installation
printf 'Updating package information...'
apt-get update

# Install PostgreSQL
printf 'Installing PostgreSQL...'
apt install postgresql -y

# Check installed version
PSQL_MAJOR_VER = postgres -V | egrep -o '[0-9]{1,}'

# Enable remote connections
printf 'Editing postgresql.conf for remote connections...'
sed -i 's/#listen_addresses=\'localhost\'/listen_addresses=\'*\'/' /etc/postgresql/$PSQL_MAJOR_VER/main/postgresql.conf 

printf 'Editing pg_hba.conf for remote connections...'
sed -i 's/host    all             all             127.0.0.1/32            scram-sha-256/host    all             all             '$vbsf_ip'/32            scram-sha-256/' /etc/postgresql/$PSQL_MAJOR_VER/main/postgresql.conf

# Restart service so changes can take effect
printf 'Restarting PostgreSQL service to apply changes...'
service postgresql restart

# Switch to postgres user to create account for Veeam to use for access
printf 'Switching to postgres user...'
su - postgres

printf 'Creating Veeam database user...'
createuser -l -d SvcVeeamBackup

# Generate random password
$veeam_password = gpg --gen-random --armor 1 14

# Apply password to account
printf SvcVeeamBackup:$veeam_password | chpasswd

# TODO: Output the password to the console for the user to copy
printf "\n\n\nPlease make sure to copy the following lines as they will NOT be saved and are needed by Veeam."
printf "Username: SvcVeeamBackup"
printf "Password: $veeam_password"

printf "\n\n\nInstallation complete!"
exit
