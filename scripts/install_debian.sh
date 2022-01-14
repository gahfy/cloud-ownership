#!/bin/bash

#Include variables.sh
source $(dirname $0)/variables.sh
SERVER_FQDN=$(hostname -f)

# Update Debian
echo "Initialization and update of the OS"
apt update > /dev/null 2>&1
apt -y upgrade > /dev/null 2>&1

################ INSTALL UFW ################
echo "Installing and configuring UFW"
apt -y install ufw > /dev/null 2>&1
ufw enable > /dev/null 2>&1
ufw logging off > /dev/null 2>&1

################ INSTALL SUDO ################
echo "Installing and configuring sudo"
apt -y install sudo > /dev/null 2>&1
echo "$USERNAME_FOR_SSH  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

################ INSTALL SSH ################
echo "Installing and configuring SSH"
apt -y install openssh-server > /dev/null 2>&1
ufw allow from $IP_CLIENT to any port 22 proto tcp > /dev/null 2>&1
mkdir /home/$USERNAME/.ssh > /dev/null 2>&1
echo $SSH_PUBLIC_KEY > /home/$USERNAME/.ssh/authorized_keys
chmod 700 /home/$USERNAME/.ssh > /dev/null 2>&1
chmod 600 /home/$USERNAME/.ssh/authorized_keys > /dev/null 2>&1
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh > /dev/null 2>&1
sed -i 's/#\(PubkeyAuthentication yes\)/\1/' /etc/ssh/sshd_config > /dev/null 2>&1
sed -i 's/#\(PasswordAuthentication\) yes/\1 no/'  /etc/ssh/sshd_config > /dev/null 2>&1
systemctl restart sshd > /dev/null 2>&1
SSHFP_RECORD="Add the following record to your DNS:\n$(ssh-keygen -r $SERVER_FQDN)"

################ INSTALL MARIADB ################
echo "Installing and configuring MariaDB"
sudo apt -y install mariadb-server > /dev/null 2>&1
mysql -u root -e "SET PASSWORD FOR 'root'@'localhost'=PASSWORD('$MARIADB_ROOT_PASSWORD');" > /dev/null 2>&1
mysql -u root -e "FLUSH PRIVILEGES;" > /dev/null 2>&1

################ INSTALL POSTFIX ################
echo "Installing and configuring Postfix"
# Configure MySQL
mysql -u root -e "CREATE DATABASE postfix;" > /dev/null 2>&1
mysql -u root -e "GRANT ALL PRIVILEGES ON postfix.* to 'mail'@'localhost' IDENTIFIED BY '$MARIADB_MAIL_PASSWD';" > /dev/null 2>&1
mysql -u root -e "FLUSH PRIVILEGES;" > /dev/null 2>&1
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "CREATE TABLE postfix.aliases(pkid smallint(3) NOT NULL auto_increment,mail varchar(120) NOT NULL default '',destination varchar(120) NOT NULL default '',enabled tinyint(1) NOT NULL default '1',PRIMARY KEY  (pkid),UNIQUE KEY mail (mail));"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "CREATE TABLE postfix.domains (pkid smallint(6) NOT NULL auto_increment,domain varchar(120) NOT NULL default '',transport varchar(120) NOT NULL default 'virtual:',enabled tinyint(1) NOT NULL default '1',PRIMARY KEY  (pkid));"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "CREATE TABLE postfix.users (id varchar(128) NOT NULL default '',name varchar(128) NOT NULL default '',uid smallint(5) unsigned NOT NULL default '5000',gid smallint(5) unsigned NOT NULL default '5000',home varchar(255) NOT NULL default '/data/mail/virtual',maildir varchar(255) NOT NULL default 'blah/',enabled tinyint(1) NOT NULL default '1',change_password tinyint(1) NOT NULL default '1',crypt varchar(128) NOT NULL,quota varchar(255) NOT NULL default '',PRIMARY KEY  (id),UNIQUE KEY id (id));"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.domains (domain) VALUES ('localhost'), ('localhost.localdomain');"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.aliases (mail,destination) VALUES('postmaster@localhost','root@localhost'),('sysadmin@localhost','root@localhost'),('webmaster@localhost','root@localhost'),('abuse@localhost','root@localhost'),('root@localhost','root@localhost'),('@localhost','root@localhost'),('@localhost.localdomain','@localhost');"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.users (id,name,maildir,crypt) VALUES ('root@localhost','root','root/',encrypt('$MAIL_ROOT_LOCALHOST_PASSWD', CONCAT('\$5\$', MD5(RAND()))) );"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.domains (domain) VALUES ('$MAIL_DOMAIN');"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.users (id,name,maildir,crypt) VALUES ('$MAIL_USER','$MAIL_USER_FULL_NAME','$MAIL_USER_FOLDER/',encrypt('$MAIL_USER_PASSWD', CONCAT('\$5\$', MD5(RAND()))) );"

# Install Postfix and Postfix-Mysql
DEBIAN_FRONTEND=noninteractive apt -y -qq install postfix postfix-mysql > /dev/null 2>&1
cp /etc/aliases /etc/postfix/aliases
postalias /etc/postfix/aliases
mkdir -p /data/mail/virtual
groupadd --system virtual -g 5000
useradd --system virtual -u 5000 -g 5000
chown -R virtual:virtual /data/mail/virtual
sed -i 's/#\(delay_warning_time = 4h\)/\1/' /etc/postfix/main.cf
sed -i 's|alias_maps = hash:/etc/aliases|alias_maps = hash:/etc/postfix/aliases|' /etc/postfix/main.cf
sed -i 's|alias_database = hash:/etc/aliases|alias_database = hash:/etc/postfix/aliases|' /etc/postfix/main.cf
echo 'virtual_mailbox_base = /data/mail/virtual' >> /etc/postfix/main.cf
echo 'virtual_mailbox_maps = mysql:/etc/postfix/mysql_mailbox.cf' >> /etc/postfix/main.cf
echo 'virtual_alias_maps = mysql:/etc/postfix/mysql_alias.cf' >> /etc/postfix/main.cf
echo 'virtual_mailbox_domains = mysql:/etc/postfix/mysql_domains.cf' >> /etc/postfix/main.cf
echo 'virtual_uid_maps = static:5000' >> /etc/postfix/main.cf
echo 'virtual_gid_maps = static:5000' >> /etc/postfix/main.cf
echo 'local_recipient_maps = ' >> /etc/postfix/main.cf
sed -i 's/mydestination =.*/mydestination =/' /etc/postfix/main.cf
echo "user=mail
password=$MARIADB_MAIL_PASSWD
dbname=postfix
table=users
select_field=maildir
where_field=id
hosts=127.0.0.1
additional_conditions = and enabled = 1" >> /etc/postfix/mysql_mailbox.cf
echo "user=mail
password=$MARIADB_MAIL_PASSWD
dbname=postfix
table=aliases
select_field=destination
where_field=mail
hosts=127.0.0.1
additional_conditions = and enabled = 1" >> /etc/postfix/mysql_domains.cf
chown root:postfix /etc/postfix/mysql_*
chmod 0640 /etc/postfix/mysql_*

# Disable authentication on port 25, then open the port to any
sed -i 's/permit_sasl_authenticated //' /etc/postfix/main.cf
ufw allow from any to any port 25 > /dev/null 2>&1
systemctl postfix restart

################ INSTALL CERTBOT ################
echo "Installing and configuring Certbot"
apt -y install certbot > /dev/null 2>&1
ufw allow from any to any port 80 > /dev/null 2>&1
certbot certonly --domain $SMTP_DOMAIN_NAME --email $MAIL_USER --agree-tos  --standalone --no-eff-email > /dev/null 2>&1

# Configuring STARTTLS
sed -i "s|smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem|smtpd_tls_cert_file=/etc/letsencrypt/live/$SMTP_DOMAIN_NAME/cert.pem|" /etc/postfix/main.cf
sed -i "s|smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key|smtpd_tls_key_file=/etc/letsencrypt/live/$SMTP_DOMAIN_NAME/privkey.pem|" /etc/postfix/main.cf

# Restart postfix
systemctl postfix restart
echo $SSHFP_RECORD
