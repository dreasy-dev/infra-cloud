#!/bin/bash -x

export DEBIAN_FRONTEND=noninteractive

# Update the package repository
sudo apt-get update

# Install necessary packages
sudo apt-get install -y \
    apache2 \
    awscli \
    libapache2-mod-php \
    mysql-client \
    nfs-common \
    php \
    php-cli \
    php-common \
    php-curl \
    php-fpm \
    php-gd \
    php-imap \
    php-mbstring \
    php-mysql \
    php-redis \
    php-xml \
    php-zip \
    unzip

# Create the mount point for the EFS file system
sudo mkdir -p /mnt/efs

# Mount the EFS file system
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns}:/ /mnt/efs

# Add the EFS mount to /etc/fstab to mount it automatically at boot
echo '${efs_dns}:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0' | sudo tee -a /etc/fstab

# Create the directory for the Nextcloud installation
sudo mkdir -p /data/www/

# Download and extract the latest Nextcloud release
cd /tmp &&
    sudo wget -q https://download.nextcloud.com/server/releases/latest.zip &&
    sudo unzip -q -d /data/www/ latest.zip

sudo sed -i "s/'dbtype' => 'mysql'/'dbtype' => 'mysql',\n    'dbname' => '${db_name}',\n    'dbhost' => '${db_host}',\n    'dbuser' => '${db_user}',\n    'dbpassword' => '${db_pass}',/" /data/www/nextcloud/config.php
# Create the data directory for Nextcloud
sudo mkdir -p /data/www/nextcloud/data

# Set the correct permissions
sudo chown -R www-data:www-data /data/www/
cd /data/www/nextcloud/

# Check if the nextcloud directory exists on the EFS
if [ ! -d /mnt/efs/nextcloud ]; then
    # Create the directory structure on the EFS
    sudo mkdir -p /mnt/efs/nextcloud/data
    sudo mkdir -p /mnt/efs/nextcloud/config

    sudo chown -R www-data:www-data /mnt/efs/nextcloud

    # Move the config directory to the EFS
    sudo rsync -azr /data/www/nextcloud/config/ /mnt/efs/nextcloud/config/ --remove-source-files

    # Mount the EFS directories to the correct locations
    sudo mount --bind /mnt/efs/nextcloud/config /data/www/nextcloud/config
    sudo mount --bind /mnt/efs/nextcloud/data /data/www/nextcloud/data

    set +x # Avoid printing password in logs

    # Install Nextcloud
    sudo -u www-data php occ maintenance:install \
        --database='mysql' \
        --database-name='${db_name}' \
        --database-host='${db_host}' \
        --database-user='${db_user}' \
        --database-pass='${db_pass}' \
        --admin-pass='N3xtcl0ud!'

    set -x # Set xtrace back

    # Set the trusted domains
    sudo -u www-data php occ config:system:set trusted_domains 1 \
        --value="${fqdn}"

    # Enable Files External app
    sudo -u www-data php occ app:enable files_external

else
    mount --bind /mnt/efs/nextcloud/config /data/www/nextcloud/config
    mount --bind /mnt/efs/nextcloud/data /data/www/nextcloud/data
fi

echo '/mnt/efs/nextcloud/config /data/www/nextcloud/config none _netdev,noatime,bind,defaults 0 0' | sudo tee -a /etc/fstab
echo '/mnt/efs/nextcloud/data /data/www/nextcloud/data none _netdev,noatime,bind,defaults 0 0' | sudo tee -a /etc/fstab

# Configure Apache
sudo sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

cat >/etc/apache2/sites-available/nextcloud.conf <<EOF
<VirtualHost *:80>
    ServerName ${fqdn}
    DocumentRoot /data/www/nextcloud
    <Directory /data/www/nextcloud>
        Require all granted
        Options FollowSymlinks MultiViews
        AllowOverride All
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>

    ErrorLog /var/log/apache2/nextcloud.error_log
    CustomLog /var/log/apache2/nextcloud.access_log common
</VirtualHost>
<VirtualHost *:443>
    ServerName ${fqdn}
    DocumentRoot /data/www/nextcloud
    <Directory /data/www/nextcloud>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews

        <IfModule mod_dav.c>
            Dav off
        </IfModule>
    </Directory>
</VirtualHost>
EOF
sudo a2ensite nextcloud.conf
sudo a2enmod rewrite
sudo systemctl restart apache2
