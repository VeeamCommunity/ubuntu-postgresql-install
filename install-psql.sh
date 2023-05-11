#!/bin/bash

# Prompt user for the VBSF IP Address
ip_invalid=true
while $ip_invalid
do
  read -p "Enter the IP address of the Veeam Backup for SF server: " vbsf_ip
  if [[ $vbsf_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    ip_invalid=false
  else
    echo "$vbsf_ip is not a valid IP address. Please try again."
  fi
done

# Update package information before installation
echo "Updating package information..."
apt-get update

# Install PostgreSQL
echo "Installing PostgreSQL..."
apt install postgresql -y

# Check installed version
PSQL_MAJOR_VER=$(psql -V | egrep -o '[0-9]{1,}' | head -n 1)

# Enable remote connections
echo "Editing postgresql.conf for remote connections..."
sed -i "s/#listen_addresses=\'localhost\'/listen_addresses=\'*\'/g" /etc/postgresql/$PSQL_MAJOR_VER/main/postgresql.conf 

echo 'Editing pg_hba.conf for remote connections...'
sed -i "s/host    all             all             127.0.0.1\/32            scram-sha-256/host    all             all             $vbsf_ip\/32            scram-sha-256/g" /etc/postgresql/$PSQL_MAJOR_VER/main/postgresql.conf

# Restart service so changes can take effect
echo "Restarting PostgreSQL service to apply changes..."
service postgresql restart

# Generate random password
veeam_password=$(gpg --gen-random --armor 1 14)

# Create account for Veeam to access the server with
echo "Creating Veeam database user..."
su - postgres -c "psql -c \"CREATE USER SvcVeeamBackup WITH PASSWORD '$veeam_password' CREATEDB LOGIN;\""

# Output the password to the console for the user to copy
echo -e "\n\n\nPlease make sure to copy the following lines as they will NOT be saved and are needed by Veeam."
echo "Username: SvcVeeamBackup"
echo "Password: $veeam_password"

echo -e "\n\n\nInstallation complete!"
exit
