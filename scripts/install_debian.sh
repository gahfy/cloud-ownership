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
mkdir /home/$USERNAME_FOR_SSH/.ssh > /dev/null 2>&1
echo $SSH_PUBLIC_KEY > /home/$USERNAME_FOR_SSH/.ssh/authorized_keys
chmod 700 /home/$USERNAME_FOR_SSH/.ssh > /dev/null 2>&1
chmod 600 /home/$USERNAME_FOR_SSH/.ssh/authorized_keys > /dev/null 2>&1
chown -R $USERNAME_FOR_SSH:$USERNAME_FOR_SSH /home/$USERNAME_FOR_SSH/.ssh > /dev/null 2>&1
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
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "CREATE TABLE postfix.users (id varchar(128) NOT NULL default '',name varchar(128) NOT NULL default '',uid smallint(5) unsigned NOT NULL default '5000',gid smallint(5) unsigned NOT NULL default '5000',home varchar(255) NOT NULL default '/data/mail/virtual',maildir varchar(255) NOT NULL default 'blah/',enabled tinyint(1) NOT NULL default '1',change_password tinyint(1) NOT NULL default '1',crypt varchar(128) NOT NULL,quota varchar(255) NOT NULL default '', regex varchar(128) default null, PRIMARY KEY  (id),UNIQUE KEY id (id));"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.domains (domain) VALUES ('localhost'), ('localhost.localdomain');"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.aliases (mail,destination) VALUES('postmaster@localhost','root@localhost'),('sysadmin@localhost','root@localhost'),('webmaster@localhost','root@localhost'),('abuse@localhost','root@localhost'),('root@localhost','root@localhost'),('@localhost','root@localhost'),('@localhost.localdomain','@localhost');"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.users (id,name,maildir,crypt) VALUES ('root@localhost','root','root/',encrypt('$MAIL_ROOT_LOCALHOST_PASSWD', CONCAT('\$5\$', MD5(RAND()))) );"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.domains (domain) VALUES ('$MAIL_DOMAIN');"
mysql -u mail -p$MARIADB_MAIL_PASSWD -e "INSERT INTO postfix.users (id,name,maildir,crypt, regex) VALUES ('$MAIL_USER','$MAIL_USER_FULL_NAME','$MAIL_USER_FOLDER/',encrypt('$MAIL_USER_PASSWD', CONCAT('\$5\$', MD5(RAND()))), '$MAIL_USER_REGEX' );"

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
query=SELECT maildir FROM users WHERE ((id='%s' AND regex IS NULL) OR '%s' REGEXP regex) AND enabled=1" >> /etc/postfix/mysql_mailbox.cf
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
certbot certonly --domain $SMTP_DOMAIN_NAME --email $MAIL_CERTBOT --agree-tos  --standalone --no-eff-email > /dev/null 2>&1
certbot certonly --domain $IMAP_DOMAIN_NAME --email $MAIL_CERTBOT --agree-tos  --standalone --no-eff-email > /dev/null 2>&1

################ INSTALL POSTFIX SSL ################
echo "Configuring SSL for Postfix"
# Configuring STARTTLS
sed -i "s|smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem|smtpd_tls_cert_file=/etc/letsencrypt/live/$SMTP_DOMAIN_NAME/cert.pem|" /etc/postfix/main.cf
sed -i "s|smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key|smtpd_tls_key_file=/etc/letsencrypt/live/$SMTP_DOMAIN_NAME/privkey.pem|" /etc/postfix/main.cf

# Configuring SMTPS
sed -i 's/#\(smtps     inet  n       -       y       -       -       smtpd\)/\1/' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_tls_wrappermode=yes\)/\1/' /etc/postfix/master.cf
sed -i ':a;N;$!ba;s/#\(  -o smtpd_sasl_auth_enable=\)yes/\1no/2' /etc/postfix/master.cf
sed -i ':a;N;$!ba;s/#\(  -o smtpd_relay_restrictions=\)permit_sasl_authenticated,reject/\1permit_mynetworks,reject/2' /etc/postfix/master.cf
ufw allow from any to any port 465

# Get TLSA record
BEGIN_LAST_CERTIFICATE_LINE_NUMBER=$(grep -n '^-----BEGIN CERTIFICATE-----$' /etc/letsencrypt/live/$SMTP_DOMAIN_NAME/fullchain.pem | cut -f1 -d: | tail -n 1)
END_LAST_CERTIFICATE_LINE_NUMBER=$(grep -n '^-----END CERTIFICATE-----$' /etc/letsencrypt/live/$SMTP_DOMAIN_NAME/fullchain.pem | cut -f1 -d: | tail -n 1)
sed -n "$BEGIN_LAST_CERTIFICATE_LINE_NUMBER,$END_LAST_CERTIFICATE_LINE_NUMBERp" /etc/letsencrypt/live/$SMTP_DOMAIN_NAME/fullchain.pem > authority_certificate.pem
TLSA_SMTP_RECORD=$(openssl x509 -in authority_certificate.pem -outform DER | openssl dgst -sha256 -hex | awk '{print $NF}')

# Configure SMTP submission
sed -i 's/#\(submission inet n       -       y       -       -       smtpd\)/\1/' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_tls_security_level=encrypt\)/\1/' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_sasl_auth_enable=yes\)/\1/' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_tls_auth_only=yes\)/\1/' /etc/postfix/master.cf
sed -i ':a;N;$!ba;s/#\(  -o smtpd_client_restrictions=\)$mua_client_restrictions/\1permit_sasl_authenticated,reject/1' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject\)/\1/' /etc/postfix/master.cf
ufw allow from any to any port 587

################ INSTALL SASL ################
echo "Installing and configuring SASL"
apt install -y libsasl2-modules libsasl2-modules-sql libgsasl7 libauthen-sasl-cyrus-perl sasl2-bin libpam-mysql
adduser postfix sasl
mkdir -p /var/spool/postfix/var/run/saslauthd
sed -i 's/START=no/START=yes/' /etc/default/saslauthd
sed -i 's|OPTIONS="-c -m /var/run/saslauthd"|OPTIONS="-r -c -m /var/spool/postfix/var/run/saslauthd"|' /etc/default/saslauthd

################ INSTALL POSTFIX SASL ################
echo "Configuring SASL for Postfix"
echo "smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = no
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain =" >> /etc/postfix/main.cf

echo "pwcheck_method: saslauthd
mech_list: plain login cram-md5 digest-md5
log_level: 7
allow_plaintext: true
auxprop_plugin: sql
sql_engine: mysql
sql_hostnames: 127.0.0.1
sql_user: mail
sql_passwd: $MARIADB_MAIL_PASSWD
sql_database: postfix
sql_select: select crypt from users where id=\'%u@%r\' and enabled = 1" >> /etc/postfix/sasl/smtpd.conf

echo "auth required pam_mysql.so user=mail passwd=$MARIADB_MAIL_PASSWD host=127.0.0.1 db=postfix table=users usercolumn=id passwdcolumn=crypt crypt=1
account sufficient pam_mysql.so user=mail passwd=$MARIADB_MAIL_PASSWD host=127.0.0.1 db=postfix table=users usercolumn=id passwdcolumn=crypt crypt=1" >> /etc/pam.d/smtp

# Restart postfix and SASL auth deamon
systemctl saslauthd restart
systemctl postfix restart

################ INSTALL DOVECOT ################
echo "Installing and configuring SASL"
apt -y install dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql
sed -i 's|\(!include_try /usr/share/dovecot/protocols.d/\*.protocol\)|\1\nprotocols = imap lmtp|' /etc/dovecot/dovecot.conf
sed -i 's/#\(disable_plaintext_auth = yes\)/\1/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/\(auth_mechanisms = plain\)/\1 login/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/\(!include auth-system.conf.ext\)/#\1/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/#\(!include auth-sql.conf.ext\)/\1/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's|mail_location = mbox:~/mail:INBOX=/var/mail/%u|mail_location = maildir:/data/mail/virtual/%u|' /etc/dovecot/conf.d/10-mail.conf
sed -i '0,/#separator =/{s//separator = ./}' /etc/dovecot/conf.d/10-mail.conf
sed -i '0,/#prefix =/{s//prefix = INBOX./}' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#\(mail_uid =\)/\1 5000/' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#\(mail_gid =\)/\1 5000/' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/\(mail_privileged_group = \)mail/\1virtual/' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/inet_listener imap \{\n    #port = 143\n  \}/#inet_listener imap \{\n    #port = 143\n  #\}/' /etc/dovecot/conf.d/10-master.conf
sed -i '0,/}/{s//#}/}' /etc/dovecot/conf.d/10-master.conf
sed -i "s|ssl_cert = </etc/dovecot/private/dovecot.pem|ssl_cert = </etc/letsencrypt/live/$IMAP_DOMAIN_NAME/cert.pem|" /etc/dovecot/conf.d/10-ssl.conf
sed -i "s|ssl_key = </etc/dovecot/private/dovecot.key|ssl_key = </etc/letsencrypt/live/$IMAP_DOMAIN_NAME/privkey.pem|" /etc/dovecot/conf.d/10-ssl.conf
sed -i 's/#\(mail_max_userip_connections = 10\)/\10/' /etc/dovecot/conf.d/20-imap.conf
sed -i ':a;N;$!ba;s/driver = sql/driver = prefetch/2' /etc/dovecot/conf.d/auth-sql.conf.ext
sed -i ':a;N;$!ba;s|\(args = /etc/dovecot/dovecot-sql.conf.ext\)|#\1|2' /etc/dovecot/conf.d/auth-sql.conf.ext
echo "#For database driver, we want mysql:
driver = mysql

#The connect string will point to the postfix database on the local machine,
#with the user and password you defined when you set it up according to Flurdy.
connect = host=127.0.0.1 dbname=postfix user=mail password=$MARIADB_MAIL_PASSWD

#We'll be using the encrypted password from the mysql database:
default_pass_scheme = CRYPT

#Set the password query to point to the users table:
password_query = SELECT id AS user, crypt AS password, CONCAT(home,'/',maildir) AS userdb_home, \
                        uid AS userdb_uid, gid AS userdb_gid, CONCAT(home,'/',maildir) AS userdb_mail FROM users WHERE id='%u" >> /etc/dovecot/dovecot-sql.conf.ext

systemctl restart dovecot
ufw allow from any to any port 993
BEGIN_LAST_CERTIFICATE_LINE_NUMBER=$(grep -n '^-----BEGIN CERTIFICATE-----$' /etc/letsencrypt/live/$IMAP_DOMAIN_NAME/fullchain.pem | cut -f1 -d: | tail -n 1)
END_LAST_CERTIFICATE_LINE_NUMBER=$(grep -n '^-----END CERTIFICATE-----$' /etc/letsencrypt/live/$IMAP_DOMAIN_NAME/fullchain.pem | cut -f1 -d: | tail -n 1)
sed -n "$BEGIN_LAST_CERTIFICATE_LINE_NUMBER,$END_LAST_CERTIFICATE_LINE_NUMBERp" /etc/letsencrypt/live/$IMAP_DOMAIN_NAME/fullchain.pem > authority_certificate.pem
TLSA_IMAP_RECORD=$(openssl x509 -in authority_certificate.pem -outform DER | openssl dgst -sha256 -hex | awk '{print $NF}')

echo $SSHFP_RECORD
echo "\n\n"
echo "TLSA => _25._tcp.$SMTP_DOMAIN_NAME => 2 0 1 $TLSA_SMTP_RECORD"
echo "TLSA => _465._tcp.$SMTP_DOMAIN_NAME => 2 0 1 $TLSA_SMTP_RECORD"
echo "TLSA => _587._tcp.$SMTP_DOMAIN_NAME => 2 0 1 $TLSA_SMTP_RECORD"
echo "TLSA => _993._tcp.$IMAP_DOMAIN_NAME => 2 0 1 $TLSA_IMAP_RECORD"
