#!/bin/bash

#Include variables.sh
source $(dirname $0)/variables.sh

# Get variables from server configuration
SERVER_HOSTNAME=$(hostname)
SERVER_DOMAIN=$(hostname -d)
SERVER_FQDN=$(hostname -f)
SERVER_IP=$(hostname -i)

# Initialize passwords
MARIADB_ROOT_PASSWD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24 ; echo '')
MARIADB_MAIL_PASSWD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24 ; echo '')
MAIL_ROOT_LOCALHOST_PASSWD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24 ; echo '')

# Updating Njal.la A record if needed
HAS_DOMAIN=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"get-domain", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_DOMAIN}"'"' | wc -l)
if [ ${HAS_DOMAIN} != '0' ]
then
  # Check that Njal.la has the right A record (normally it should be the case, as configuration asks for reverse DNS)
  GOOD_RECORD=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "A", "content": "'"${SERVER_IP}"'"' | wc -l)

  # If there is no correct record
  if [ ${GOOD_RECORD} = '0' ]
  then
    WRONG_RECORD=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "A", "content": "'"[0-9\.]*"'"' | wc -l)
    if [ ${WRONG_RECORD} = '0' ]
    then
      # Add A record
      echo "Adding A record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${SERVER_HOSTNAME}"'", "content": "'"${SERVER_IP}"'", "type": "A", "ttl": "86400"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit record
      echo "Edit record to match the IP address of this server"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${SERVER_HOSTNAME}"'".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${SERVER_IP}"'", "ttl": "86400"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an A record pointing to this server"
  fi
else
  echo "Won't configure Njal.la as we cannot find the domain of the server"
fi

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
echo "${USERNAME_FOR_SSH}  ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

################ INSTALL SSH ################
echo "Installing and configuring SSH"
apt -y install openssh-server > /dev/null 2>&1
ufw allow from ${IP_CLIENT} to any port 22 proto tcp > /dev/null 2>&1
mkdir /home/${USERNAME_FOR_SSH}/.ssh > /dev/null 2>&1
echo ${SSH_PUBLIC_KEY} > /home/${USERNAME_FOR_SSH}/.ssh/authorized_keys
chmod 700 /home/${USERNAME_FOR_SSH}/.ssh > /dev/null 2>&1
chmod 600 /home/${USERNAME_FOR_SSH}/.ssh/authorized_keys > /dev/null 2>&1
chown -R ${USERNAME_FOR_SSH}:${USERNAME_FOR_SSH} /home/${USERNAME_FOR_SSH}/.ssh > /dev/null 2>&1
sed -i 's/#\(PubkeyAuthentication yes\)/\1/' /etc/ssh/sshd_config > /dev/null 2>&1
sed -i 's/#\(PasswordAuthentication\) yes/\1 no/'  /etc/ssh/sshd_config > /dev/null 2>&1
systemctl restart sshd > /dev/null 2>&1
RSA_SHA1_SSHFP_RECORD=$(ssh-keygen -r ${SERVER_FQDN} | tr '\n' ' ' | sed "s/^.*${SERVER_FQDN} IN SSHFP 1 1 \([a-z0-9]\+\).*/\1/g")
RSA_SHA256_SSHFP_RECORD=$(ssh-keygen -r ${SERVER_FQDN} | tr '\n' ' ' | sed "s/^.*${SERVER_FQDN} IN SSHFP 1 2 \([a-z0-9]\+\).*/\1/g")
ECDSA_SHA1_SSHFP_RECORD=$(ssh-keygen -r ${SERVER_FQDN} | tr '\n' ' ' | sed "s/^.*${SERVER_FQDN} IN SSHFP 3 1 \([a-z0-9]\+\).*/\1/g")
ECDSA_SHA256_SSHFP_RECORD=$(ssh-keygen -r ${SERVER_FQDN} | tr '\n' ' ' | sed "s/^.*${SERVER_FQDN} IN SSHFP 3 2 \([a-z0-9]\+\).*/\1/g")
ED25519_SHA1_SSHFP_RECORD=$(ssh-keygen -r ${SERVER_FQDN} | tr '\n' ' ' | sed "s/^.*${SERVER_FQDN} IN SSHFP 4 1 \([a-z0-9]\+\).*/\1/g")
ED25519_SHA256_SSHFP_RECORD=$(ssh-keygen -r ${SERVER_FQDN} | tr '\n' ' ' | sed "s/^.*${SERVER_FQDN} IN SSHFP 4 2 \([a-z0-9]\+\).*/\1/g")
if [ ${HAS_DOMAIN} != '0' ]
then
  HAS_GOOD_RSA_SHA1=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "'"${RSA_SHA1_SSHFP_RECORD}"'", "ttl": [0-9]\+, "ssh_algorithm": 1, "ssh_type": 1' | wc -l)
  if [ ${HAS_GOOD_RSA_SHA1} = '0' ]
  then
    HAS_WRONG_RSA_SHA1=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]*", "ttl": [0-9]\+, "ssh_algorithm": 1, "ssh_type": 1' | wc -l)
    if [ ${HAS_WRONG_RSA_SHA1} = '0' ]
    then
      # Add SSHFP record
      echo "Adding SSHFP RSA SHA1 record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${SERVER_HOSTNAME}"'", "content": "'"${RSA_SHA1_SSHFP_RECORD}"'", "ttl": "86400", "type": "SSHFP", "ssh_algorithm": 1, "ssh_type": 1 }}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit SSHFP RSA SHA1 record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]*", "ttl": [0-9]*, "ssh_algorithm": 1, "ssh_type": 1.*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${RSA_SHA1_SSHFP_RECORD}"'", "ssh_algorithm": 1, "ssh_type": 1}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an SSHFP RSA SHA1 record pointing to this SSH instance"
  fi

  HAS_GOOD_RSA_SHA256=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "'"${RSA_SHA256_SSHFP_RECORD}"'", "ttl": [0-9]\+, "ssh_algorithm": 1, "ssh_type": 2' | wc -l)
  if [ ${HAS_GOOD_RSA_SHA256} = '0' ]
  then
    HAS_WRONG_RSA_SHA256=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]\+", "ttl": [0-9]\+, "ssh_algorithm": 1, "ssh_type": 2' | wc -l)
    if [ ${HAS_WRONG_RSA_SHA256} = '0' ]
    then
      # Add SSHFP record
      echo "Adding SSHFP RSA SHA256 record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${SERVER_HOSTNAME}"'", "content": "'"${RSA_SHA256_SSHFP_RECORD}"'", "ttl": "86400", "type": "SSHFP", "ssh_algorithm": 1, "ssh_type": 2 }}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit SSHFP RSA SHA256 record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]*", "ttl": [0-9]*, "ssh_algorithm": 1, "ssh_type": 2.*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${RSA_SHA256_SSHFP_RECORD}"'", "ssh_algorithm": 1, "ssh_type": 2}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an SSHFP RSA SHA256 record pointing to this SSH instance"
  fi

  HAS_GOOD_ECDSA_SHA1=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "'"${ECDSA_SHA1_SSHFP_RECORD}"'", "ttl": [0-9]\+, "ssh_algorithm": 3, "ssh_type": 1' | wc -l)
  if [ ${HAS_GOOD_ECDSA_SHA1} = '0' ]
  then
    HAS_WRONG_ECDSA_SHA1=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]\+", "ttl": [0-9]\+, "ssh_algorithm": 3, "ssh_type": 1' | wc -l)
    if [ ${HAS_WRONG_ECDSA_SHA1} = '0' ]
    then
      # Add SSHFP record
      echo "Adding SSHFP ECDSA SHA1 record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${SERVER_HOSTNAME}"'", "content": "'"${ECDSA_SHA1_SSHFP_RECORD}"'", "ttl": "86400", "type": "SSHFP", "ssh_algorithm": 3, "ssh_type": 1 }}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit SSHFP ECDSA SHA1 record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]*", "ttl": [0-9]*, "ssh_algorithm": 3, "ssh_type": 1.*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${ECDSA_SHA1_SSHFP_RECORD}"'", "ssh_algorithm": 3, "ssh_type": 1}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an SSHFP ECDSA SHA1 record pointing to this SSH instance"
  fi

  HAS_GOOD_ECDSA_SHA256=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "'"${ECDSA_SHA256_SSHFP_RECORD}"'", "ttl": [0-9]\+, "ssh_algorithm": 3, "ssh_type": 2' | wc -l)
  if [ ${HAS_GOOD_ECDSA_SHA256} = '0' ]
  then
    HAS_WRONG_ECDSA_SHA256=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]\+", "ttl": [0-9]\+, "ssh_algorithm": 3, "ssh_type": 2' | wc -l)
    if [ ${HAS_WRONG_ECDSA_SHA256} = '0' ]
    then
      # Add SSHFP record
      echo "Adding SSHFP ECDSA SHA256 record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${SERVER_HOSTNAME}"'", "content": "'"${ECDSA_SHA256_SSHFP_RECORD}"'", "ttl": "86400", "type": "SSHFP", "ssh_algorithm": 3, "ssh_type": 2 }}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit SSHFP ECDSA SHA256 record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]*", "ttl": [0-9]*, "ssh_algorithm": 3, "ssh_type": 2.*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${ECDSA_SHA256_SSHFP_RECORD}"'", "ssh_algorithm": 3, "ssh_type": 2}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an SSHFP ECDSA SHA256 record pointing to this SSH instance"
  fi

  HAS_GOOD_ED25519_SHA1=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "'"${ED25519_SHA1_SSHFP_RECORD}"'", "ttl": [0-9]\+, "ssh_algorithm": 4, "ssh_type": 1' | wc -l)
  if [ ${HAS_GOOD_ED25519_SHA1} = '0' ]
  then
    HAS_WRONG_ED25519_SHA1=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]\+", "ttl": [0-9]\+, "ssh_algorithm": 4, "ssh_type": 1' | wc -l)
    if [ ${HAS_WRONG_ED25519_SHA1} = '0' ]
    then
      # Add SSHFP record
      echo "Adding SSHFP ED25519 SHA1 record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${SERVER_HOSTNAME}"'", "content": "'"${ED25519_SHA1_SSHFP_RECORD}"'", "ttl": "86400", "type": "SSHFP", "ssh_algorithm": 4, "ssh_type": 1 }}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit SSHFP ED25519 SHA1 record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]*", "ttl": [0-9]*, "ssh_algorithm": 4, "ssh_type": 1.*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${ED25519_SHA1_SSHFP_RECORD}"'", "ssh_algorithm": 4, "ssh_type": 1}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an SSHFP ED25519 SHA1 record pointing to this SSH instance"
  fi

  HAS_GOOD_ED25519_SHA256=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "'"${ED25519_SHA256_SSHFP_RECORD}"'", "ttl": [0-9]\+, "ssh_algorithm": 4, "ssh_type": 2' | wc -l)
  if [ ${HAS_GOOD_ED25519_SHA256} = '0' ]
  then
    HAS_WRONG_ED25519_SHA256=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]\+", "ttl": [0-9]\+, "ssh_algorithm": 4, "ssh_type": 2' | wc -l)
    if [ ${HAS_WRONG_ED25519_SHA256} = '0' ]
    then
      # Add SSHFP record
      echo "Adding SSHFP ED25519 SHA256 record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${SERVER_HOSTNAME}"'", "content": "'"${ED25519_SHA256_SSHFP_RECORD}"'", "ttl": "86400", "type": "SSHFP", "ssh_algorithm": 4, "ssh_type": 2 }}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit SSHFP ECDSA ED25519 record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${SERVER_HOSTNAME}"'", "type": "SSHFP", "content": "[a-z0-9]*", "ttl": [0-9]*, "ssh_algorithm": 4, "ssh_type": 2.*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${ED25519_SHA256_SSHFP_RECORD}"'", "ssh_algorithm": 1, "ssh_type": 2}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an SSHFP ED25519 SHA256 record pointing to this SSH instance"
  fi
else
  echo "Won't configure Njal.la for SSHFP as we cannot find the domain of the server"
fi


################ INSTALL MARIADB ################
echo "Installing and configuring MariaDB"
sudo apt -y install mariadb-server > /dev/null 2>&1
mysql -u root -e "SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MARIADB_ROOT_PASSWD}');" > /dev/null 2>&1
mysql -u root -e "FLUSH PRIVILEGES;" > /dev/null 2>&1

################ INSTALL POSTFIX ################
echo "Installing and configuring Postfix"
# Configure MySQL
mysql -u root -e "CREATE DATABASE postfix;" > /dev/null 2>&1
mysql -u root -e "GRANT ALL PRIVILEGES ON postfix.* to 'mail'@'localhost' IDENTIFIED BY '${MARIADB_MAIL_PASSWD}';" > /dev/null 2>&1
mysql -u root -e "FLUSH PRIVILEGES;" > /dev/null 2>&1
mysql -u mail -p${MARIADB_MAIL_PASSWD} -e "CREATE TABLE postfix.aliases(pkid smallint(3) NOT NULL auto_increment,mail varchar(120) NOT NULL default '',destination varchar(120) NOT NULL default '',enabled tinyint(1) NOT NULL default '1',PRIMARY KEY  (pkid),UNIQUE KEY mail (mail));"
mysql -u mail -p${MARIADB_MAIL_PASSWD} -e "CREATE TABLE postfix.domains (pkid smallint(6) NOT NULL auto_increment,domain varchar(120) NOT NULL default '',transport varchar(120) NOT NULL default 'virtual:',enabled tinyint(1) NOT NULL default '1',PRIMARY KEY  (pkid));"
mysql -u mail -p${MARIADB_MAIL_PASSWD} -e "CREATE TABLE postfix.users (id varchar(128) NOT NULL default '',name varchar(128) NOT NULL default '',uid smallint(5) unsigned NOT NULL default '5000',gid smallint(5) unsigned NOT NULL default '5000',home varchar(255) NOT NULL default '/data/mail/virtual',maildir varchar(255) NOT NULL default 'blah/',enabled tinyint(1) NOT NULL default '1',change_password tinyint(1) NOT NULL default '1',crypt varchar(128) NOT NULL,quota varchar(255) NOT NULL default '', regex varchar(128) default null, PRIMARY KEY  (id),UNIQUE KEY id (id));"
mysql -u mail -p${MARIADB_MAIL_PASSWD} -e "INSERT INTO postfix.domains (domain) VALUES ('localhost'), ('localhost.localdomain');"
mysql -u mail -p${MARIADB_MAIL_PASSWD} -e "INSERT INTO postfix.aliases (mail,destination) VALUES('postmaster@localhost','root@localhost'),('sysadmin@localhost','root@localhost'),('webmaster@localhost','root@localhost'),('abuse@localhost','root@localhost'),('root@localhost','root@localhost'),('@localhost','root@localhost'),('@localhost.localdomain','@localhost');"
mysql -u mail -p${MARIADB_MAIL_PASSWD} -e "INSERT INTO postfix.users (id,name,maildir,crypt) VALUES ('root@localhost','root','root/',encrypt('${MAIL_ROOT_LOCALHOST_PASSWD}', CONCAT('\$5\$', MD5(RAND()))) );"
mysql -u mail -p${MARIADB_MAIL_PASSWD} -e "INSERT INTO postfix.domains (domain) VALUES ('${SERVER_DOMAIN}');"
mysql -u mail -p${MARIADB_MAIL_PASSWD} -e "INSERT INTO postfix.users (id,name,maildir,crypt, regex) VALUES ('${MAIL_USER}','${MAIL_USER_FULL_NAME}','${MAIL_USER_FOLDER}/',encrypt('${MAIL_USER_PASSWD}', CONCAT('\$5\$', MD5(RAND()))), '${MAIL_USER_REGEX}' );"

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
password=${MARIADB_MAIL_PASSWD}
dbname=postfix
table=users
query=SELECT maildir FROM users WHERE ((id='%s' AND regex IS NULL) OR '%s' REGEXP regex) AND enabled=1" >> /etc/postfix/mysql_mailbox.cf
echo "user=mail
password=${MARIADB_MAIL_PASSWD}
dbname=postfix
table=aliases
select_field=destination
where_field=mail
hosts=127.0.0.1
additional_conditions = and enabled = 1" >> /etc/postfix/mysql_domains.cf
echo "user=mail
password=${MARIADB_MAIL_PASSWD}
dbname=postfix
table=aliases
select_field=destination
where_field=mail
hosts=127.0.0.1
additional_conditions = and enabled = 1" >> /etc/postfix/mysql_alias.cf
chown root:postfix /etc/postfix/mysql_*
chmod 0640 /etc/postfix/mysql_*
mkdir -p /data/mail/virtual/${MAIL_USER_FOLDER}
mkdir -p /data/mail/virtual/${MAIL_USER_FOLDER}/cur
mkdir -p /data/mail/virtual/${MAIL_USER_FOLDER}/new
mkdir -p /data/mail/virtual/${MAIL_USER_FOLDER}/tmp
chown -R virtual:virtual /data/mail/virtual/${MAIL_USER_FOLDER}
chmod -R 700 /data/mail/virtual/${MAIL_USER_FOLDER}

# Disable authentication on port 25, then open the port to any
sed -i 's/permit_sasl_authenticated //' /etc/postfix/main.cf
sudo sed -i 's/\(smtp      inet  n       -       y       -       -       smtpd\)/\1\n  -o smtpd_sasl_auth_enable=no\n  -o smtpd_relay_restrictions=permit_mynetworks,reject/' /etc/postfix/master.cf
ufw allow from any to any port 25 > /dev/null 2>&1
systemctl restart postfix

if [ ${HAS_DOMAIN} != '0' ]
then
  GOOD_RECORD=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SMTP_HOSTNAME}"'", "type": "CNAME", "content": "'"${SERVER_HOSTNAME}"'"' | wc -l)
  if [ ${GOOD_RECORD} = '0' ]
  then
    WRONG_RECORD=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${SMTP_HOSTNAME}"'", "type": "CNAME", "content": "'"[^\"]*"'"' | wc -l)
    if [ ${WRONG_RECORD} = '0' ]
    then
      # Add A record
      echo "Adding CNAME record for SMTP"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${SMTP_HOSTNAME}"'", "content": "'"${SERVER_HOSTNAME}"'", "type": "CNAME", "ttl": "86400"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit record
      echo "Edit record to match the server hostname for SMTP"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${SMTP_HOSTNAME}"'".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${SERVER_HOSTNAME}"'", "ttl": "86400"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an SMTP CNAME record pointing to this server"
  fi

  GOOD_RECORD=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${IMAP_HOSTNAME}"'", "type": "CNAME", "content": "'"${SERVER_HOSTNAME}"'"' | wc -l)
  if [ ${GOOD_RECORD} = '0' ]
  then
    WRONG_RECORD=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${IMAP_HOSTNAME}"'", "type": "CNAME", "content": "'"[^\"]*"'"' | wc -l)
    if [ ${WRONG_RECORD} = '0' ]
    then
      # Add A record
      echo "Adding CNAME record for IMAP"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${IMAP_HOSTNAME}"'", "content": "'"${SERVER_HOSTNAME}"'", "type": "CNAME", "ttl": "86400"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit record
      echo "Edit record to match the server hostname for IMAP"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${IMAP_HOSTNAME}"'".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${SERVER_HOSTNAME}"'", "ttl": "86400"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an IMAP CNAME record pointing to this server"
  fi

  GOOD_RECORD=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${ROUNDCUBE_HOSTNAME}"'", "type": "CNAME", "content": "'"${SERVER_HOSTNAME}"'"' | wc -l)
  if [ ${GOOD_RECORD} = '0' ]
  then
    WRONG_RECORD=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "'"${ROUNDCUBE_HOSTNAME}"'", "type": "CNAME", "content": "'"[^\"]*"'"' | wc -l)
    if [ ${WRONG_RECORD} = '0' ]
    then
      # Add A record
      echo "Adding CNAME record for Roundcube"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "'"${ROUNDCUBE_HOSTNAME}"'", "content": "'"${SERVER_HOSTNAME}"'", "type": "CNAME", "ttl": "86400"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit record
      echo "Edit record to match the server hostname for Roundcube"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "'"${ROUNDCUBE_HOSTNAME}"'".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'"${SERVER_HOSTNAME}"'", "ttl": "86400"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an Roundcube CNAME record pointing to this server"
  fi
fi

################ INSTALL CERTBOT ################
echo "Installing and configuring Certbot"
apt -y install certbot > /dev/null 2>&1
ufw allow from any to any port 80 > /dev/null 2>&1
certbot certonly --domain ${SMTP_HOSTNAME}.${SERVER_DOMAIN} --email ${MAIL_CERTBOT} --agree-tos  --standalone --no-eff-email --keep-until-expiring > /dev/null 2>&1
certbot certonly --domain ${IMAP_HOSTNAME}.${SERVER_DOMAIN} --email ${MAIL_CERTBOT} --agree-tos  --standalone --no-eff-email --keep-until-expiring > /dev/null 2>&1
certbot certonly --domain ${ROUNDCUBE_HOSTNAME}.${SERVER_DOMAIN} --email ${MAIL_CERTBOT} --agree-tos  --standalone --no-eff-email --keep-until-expiring > /dev/null 2>&1

################ INSTALL POSTFIX SSL ################
echo "Configuring SSL for Postfix"
# Configuring STARTTLS
sed -i "s|smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem|smtpd_tls_cert_file=/etc/letsencrypt/live/${SMTP_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem|" /etc/postfix/main.cf
sed -i "s|smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key|smtpd_tls_key_file=/etc/letsencrypt/live/${SMTP_HOSTNAME}.${SERVER_DOMAIN}/privkey.pem|" /etc/postfix/main.cf

# Configuring SMTPS
sed -i 's/#\(smtps     inet  n       -       y       -       -       smtpd\)/\1/' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_tls_wrappermode=yes\)/\1/' /etc/postfix/master.cf
sed -i ':a;N;$!ba;s/#\(  -o smtpd_sasl_auth_enable=\)yes/\1no/2' /etc/postfix/master.cf
sed -i ':a;N;$!ba;s/#\(  -o smtpd_relay_restrictions=\)permit_sasl_authenticated,reject/\1permit_mynetworks,reject/2' /etc/postfix/master.cf
ufw allow from any to any port 465 proto tcp > /dev/null 2>&1

# Get TLSA record
BEGIN_LAST_CERTIFICATE_LINE_NUMBER=$(grep -n '^-----BEGIN CERTIFICATE-----$' /etc/letsencrypt/live/${SMTP_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem | cut -f1 -d: | tail -n 1)
END_LAST_CERTIFICATE_LINE_NUMBER=$(grep -n '^-----END CERTIFICATE-----$' /etc/letsencrypt/live/${SMTP_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem | cut -f1 -d: | tail -n 1)
sed -n "${BEGIN_LAST_CERTIFICATE_LINE_NUMBER},${END_LAST_CERTIFICATE_LINE_NUMBER}p" /etc/letsencrypt/live/${SMTP_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem > authority_certificate.pem
TLSA_SMTP_RECORD=$(openssl x509 -in authority_certificate.pem -outform DER | openssl dgst -sha256 -hex | awk '{print $NF}')

if [ ${HAS_DOMAIN} != '0' ]
then
  HAS_GOOD_SMTPS_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "_465._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'"' | wc -l)
  if [ ${HAS_GOOD_SMTPS_TLSA} = '0' ]
  then
    HAS_WRONG_SMTPS_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "_465._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "[a-z0-9 ]*"' | wc -l)
    if [ ${HAS_WRONG_SMTPS_TLSA} = '0' ]
    then
      # Add SSHFP record
      echo "Adding SMTPS TLSA record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "_465._tcp.'"${SMTP_HOSTNAME}"'", "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'", "ttl": "86400", "type": "TLSA"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit SMTPS TLSA record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "_465._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "[a-z0-9 ]*".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an TLSA record for SMTPS with the right value."
  fi

  HAS_GOOD_SMTP_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "_25._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'"' | wc -l)
  if [ ${HAS_GOOD_SMTP_TLSA} = '0' ]
  then
    HAS_WRONG_SMTP_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "_25._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "[a-z0-9 ]*"' | wc -l)
    if [ ${HAS_WRONG_SMTP_TLSA} = '0' ]
    then
      # Add SSHFP record
      echo "Adding SMTP TLSA record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "_25._tcp.'"${SMTP_HOSTNAME}"'", "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'", "ttl": "86400", "type": "TLSA"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit SMTP TLSA record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "_25._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "[a-z0-9 ]*".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an TLSA record for SMTP with the right value."
  fi
fi

# Configure SMTP submission
sed -i 's/#\(submission inet n       -       y       -       -       smtpd\)/\1/' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_tls_security_level=encrypt\)/\1/' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_sasl_auth_enable=yes\)/\1/' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_tls_auth_only=yes\)/\1/' /etc/postfix/master.cf
sed -i ':a;N;$!ba;s/#\(  -o smtpd_client_restrictions=\)$mua_client_restrictions/\1permit_sasl_authenticated,reject/1' /etc/postfix/master.cf
sed -i 's/#\(  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject\)/\1/' /etc/postfix/master.cf
ufw allow from any to any port 587 proto tcp > /dev/null 2>&1

if [ ${HAS_DOMAIN} != '0' ]
then
  HAS_GOOD_SUBMISSION_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "_587._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'"' | wc -l)
  if [ ${HAS_GOOD_SUBMISSION_TLSA} = '0' ]
  then
    HAS_WRONG_SUBMISSION_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "_587._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "[a-z0-9 ]*"' | wc -l)
    if [ ${HAS_WRONG_SUBMISSION_TLSA} = '0' ]
    then
      # Add SSHFP record
      echo "Adding Submission TLSA record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "_587._tcp.'"${SMTP_HOSTNAME}"'", "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'", "ttl": "86400", "type": "TLSA"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit Submission TLSA record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "_587._tcp.'"${SMTP_HOSTNAME}"'", "type": "TLSA", "content": "[a-z0-9 ]*".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "2 0 1 '"${TLSA_SMTP_RECORD}"'"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an TLSA record for submission with the right value."
  fi
fi

################ INSTALL SASL ################
echo "Installing and configuring SASL"
apt install -y libsasl2-modules libsasl2-modules-sql libgsasl7 libauthen-sasl-cyrus-perl sasl2-bin libpam-mysql > /dev/null 2>&1
adduser postfix sasl > /dev/null 2>&1
mkdir -p /var/spool/postfix/var/run/saslauthd > /dev/null 2>&1
sed -i 's/START=no/START=yes/' /etc/default/saslauthd
sed -i 's|OPTIONS="-c -m /var/run/saslauthd"|OPTIONS="-r -c -m /var/spool/postfix/var/run/saslauthd"|' /etc/default/saslauthd

################ INSTALL POSTFIX SASL ################
echo "Configuring SASL for Postfix"
echo "smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = no
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain =" >> /etc/postfix/main.cf

echo "pwcheck_method: saslauthd
mech_list: plain login cram-md5
log_level: 7
allow_plaintext: true
auxprop_plugin: sql
sql_engine: mysql
sql_hostnames: 127.0.0.1
sql_user: mail
sql_passwd: ${MARIADB_MAIL_PASSWD}
sql_database: postfix
sql_select: select crypt from users where id='%u@%r' and enabled = 1" >> /etc/postfix/sasl/smtpd.conf

echo "auth required pam_mysql.so user=mail passwd=${MARIADB_MAIL_PASSWD} host=127.0.0.1 db=postfix table=users usercolumn=id passwdcolumn=crypt crypt=1
account sufficient pam_mysql.so user=mail passwd=${MARIADB_MAIL_PASSWD} host=127.0.0.1 db=postfix table=users usercolumn=id passwdcolumn=crypt crypt=1" >> /etc/pam.d/smtp

# Restart postfix and SASL auth deamon
systemctl restart saslauthd > /dev/null 2>&1
systemctl restart postfix > /dev/null 2>&1

################ INSTALL DKIM ################
echo "Configuring DKIM for Postfix"
apt install -y opendkim opendkim-tools > /dev/null 2>&1
echo 'AutoRestart             Yes
AutoRestartRate         10/1h' >> /etc/opendkim.conf
sed -i 's/UMask\t\t\t007/UMask\t\t\t002/' /etc/opendkim.conf
sed -i 's/#LogWhy\t\t\tno/LogWhy\t\t\tyes/' /etc/opendkim.conf
sed -i 's|#InternalHosts		192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12|ExternalIgnoreList      refile:/data/opendkim/TrustedHosts\nInternalHosts           refile:/data/opendkim/TrustedHosts\nKeyTable                refile:/data/opendkim/KeyTable\nSigningTable            refile:/data/opendkim/SigningTable\n|' /etc/opendkim.conf
sed -i 's/#Mode\t\t\tsv/Mode\t\t\tsv/' /etc/opendkim.conf
sed -i 's|PidFile\t\t\t/run/opendkim/opendkim.pid|PidFile\t\t\t/var/run/opendkim/opendkim.pid\nSignatureAlgorithm      rsa-sha256|' /etc/opendkim.conf
sed -i 's/UserID\t\t\topendkim/UserID\t\t\topendkim:opendkim/' /etc/opendkim.conf
sed -i 's|Socket\t\t\tlocal:/run/opendkim/opendkim.sock|Socket                  inet:12301@localhost|' /etc/opendkim.conf
sed -i 's|SOCKET=local:$RUNDIR/opendkim.sock|SOCKET="inet:12301@localhost"|' /etc/default/opendkim
echo 'milter_protocol = 2
milter_default_action = accept
smtpd_milters = inet:localhost:12301
non_smtpd_milters = inet:localhost:12301' >> /etc/postfix/main.cf
mkdir -p /data/opendkim/keys > /dev/null 2>&1
echo "127.0.0.1
localhost
192.168.0.1/24

*.${SERVER_DOMAIN}" >> /data/opendkim/TrustedHosts
echo "mail._domainkey.${SERVER_DOMAIN} ${SERVER_DOMAIN}:mail:/data/opendkim/keys/${SERVER_DOMAIN}/mail.private" >> /data/opendkim/KeyTable
echo "*@${SERVER_DOMAIN} mail._domainkey.${SERVER_DOMAIN}" >> /data/opendkim/SigningTable
mkdir /data/opendkim/keys/${SERVER_DOMAIN} > /dev/null 2>&1
opendkim-genkey -s mail -d ${SERVER_DOMAIN} > /dev/null 2>&1
mv mail.private /data/opendkim/keys/${SERVER_DOMAIN}/ > /dev/null 2>&1
mv mail.txt /data/opendkim/keys/${SERVER_DOMAIN}/ > /dev/null 2>&1
chown -R opendkim:opendkim /data/opendkim > /dev/null 2>&1
DKIM_RECORD=$(cat /data/opendkim/keys/${SERVER_DOMAIN}/mail.txt | tr '\n' ' ' | sed 's/mail._domainkey\tIN\tTXT\t( //' | sed "s/ )  ; ----- DKIM key mail for ${SERVER_DOMAIN}//"  | sed 's/" \t  "//g')
JSON_DKIM_RECORD=$(echo $DKIM_RECORD | sed 's/"/\\"/g')
if [ ${HAS_DOMAIN} != '0' ]
then
  HAS_GOOD_DKIM=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "mail._domainkey", "type": "TXT", "content": "'"${JSON_DKIM_RECORD}"'"' | wc -l)
  if [ ${HAS_GOOD_SUBMISSION_TLSA} = '0' ]
  then
    HAS_WRONG_SUBMISSION_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "mail._domainkey", "type": "TLSA"' | wc -l)
    if [ ${HAS_WRONG_SUBMISSION_TLSA} = '0' ]
    then
      # Add SSHFP record
      echo "Adding DKIM TXT record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "mail._domainkey", "content": "'${JSON_DKIM_RECORD}'", "ttl": "86400", "type": "TXT"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit DKIM TXT record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "mail._domainkey", "type": "TXT".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "'${JSON_DKIM_RECORD}'"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an DKIM record with the right value."
  fi
fi


################ INSTALL DOVECOT ################
echo "Installing and configuring Dovecot"
apt -y install dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql > /dev/null 2>&1
sed -i 's|\(!include_try /usr/share/dovecot/protocols.d/\*.protocol\)|\1\nprotocols = imap lmtp|' /etc/dovecot/dovecot.conf
sed -i 's/#\(disable_plaintext_auth = yes\)/\1/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/\(auth_mechanisms = plain\)/\1 login/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/\(!include auth-system.conf.ext\)/#\1/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's/#\(!include auth-sql.conf.ext\)/\1/' /etc/dovecot/conf.d/10-auth.conf
sed -i 's|mail_location = mbox:~/mail:INBOX=/var/mail/%u|mail_location = maildir:/data/mail/virtual/%u|' /etc/dovecot/conf.d/10-mail.conf
sed -i ':a;N;$!ba;s/#separator =/separator = ./1' /etc/dovecot/conf.d/10-mail.conf
sed -i ':a;N;$!ba;s/#prefix =/prefix = INBOX./1' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#\(mail_uid =\)/\1 5000/' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/#\(mail_gid =\)/\1 5000/' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/\(mail_privileged_group = \)mail/\1virtual/' /etc/dovecot/conf.d/10-mail.conf
sed -i 's/inet_listener imap {/#inet_listener imap {/' /etc/dovecot/conf.d/10-master.conf
sed -i '0,/}/{s//#}/}' /etc/dovecot/conf.d/10-master.conf
sed -i "s|ssl_cert = </etc/dovecot/private/dovecot.pem|ssl_cert = </etc/letsencrypt/live/${IMAP_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem|" /etc/dovecot/conf.d/10-ssl.conf
sed -i "s|ssl_key = </etc/dovecot/private/dovecot.key|ssl_key = </etc/letsencrypt/live/${IMAP_HOSTNAME}.${SERVER_DOMAIN}/privkey.pem|" /etc/dovecot/conf.d/10-ssl.conf
sed -i 's/#\(mail_max_userip_connections = 10\)/\10/' /etc/dovecot/conf.d/20-imap.conf
sed -i ':a;N;$!ba;s/driver = sql/driver = prefetch/2' /etc/dovecot/conf.d/auth-sql.conf.ext
sed -i ':a;N;$!ba;s|\(args = /etc/dovecot/dovecot-sql.conf.ext\)|#\1|2' /etc/dovecot/conf.d/auth-sql.conf.ext
echo "#For database driver, we want mysql:
driver = mysql

#The connect string will point to the postfix database on the local machine,
#with the user and password you defined when you set it up according to Flurdy.
connect = host=127.0.0.1 dbname=postfix user=mail password=${MARIADB_MAIL_PASSWD}

#We'll be using the encrypted password from the mysql database:
default_pass_scheme = CRYPT

#Set the password query to point to the users table:
password_query = SELECT id AS user, crypt AS password, CONCAT(home,'/',maildir) AS userdb_home, \
                        uid AS userdb_uid, gid AS userdb_gid, CONCAT(home,'/',maildir) AS userdb_mail FROM users WHERE id='%u'" >> /etc/dovecot/dovecot-sql.conf.ext

systemctl restart dovecot > /dev/null 2>&1
ufw allow from any to any port 993 proto tcp > /dev/null 2>&1

BEGIN_LAST_CERTIFICATE_LINE_NUMBER=$(grep -n '^-----BEGIN CERTIFICATE-----$' /etc/letsencrypt/live/${IMAP_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem | cut -f1 -d: | tail -n 1)
END_LAST_CERTIFICATE_LINE_NUMBER=$(grep -n '^-----END CERTIFICATE-----$' /etc/letsencrypt/live/${IMAP_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem | cut -f1 -d: | tail -n 1)
sed -n "${BEGIN_LAST_CERTIFICATE_LINE_NUMBER},${END_LAST_CERTIFICATE_LINE_NUMBER}p" /etc/letsencrypt/live/${IMAP_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem > authority_certificate.pem
TLSA_IMAP_RECORD=$(openssl x509 -in authority_certificate.pem -outform DER | openssl dgst -sha256 -hex | awk '{print $NF}')

if [ ${HAS_DOMAIN} != '0' ]
then
  HAS_GOOD_IMAP_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "_993._tcp.'"${IMAP_HOSTNAME}"'", "type": "TLSA", "content": "2 0 1 '"${TLSA_IMAP_RECORD}"'"' | wc -l)
  if [ ${HAS_GOOD_IMAP_TLSA} = '0' ]
  then
    HAS_WRONG_IMAP_TLSA=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | grep '"name": "_993._tcp.'"${IMAP_HOSTNAME}"'", "type": "TLSA", "content": "[a-z0-9 ]*"' | wc -l)
    if [ ${HAS_WRONG_IMAP_TLSA} = '0' ]
    then
      # Add SSHFP record
      echo "Adding Submission TLSA record"
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"add-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "name": "_993._tcp.'"${IMAP_HOSTNAME}"'", "content": "2 0 1 '"${TLSA_IMAP_RECORD}"'", "ttl": "86400", "type": "TLSA"}}' https://njal.la/api/1/ > /dev/null 2>&1
    else
      # Edit SSHFP record
      echo "Edit Submission TLSA record"
      RECORD_ID=$(curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"list-records", "params": {"domain": "'"${SERVER_DOMAIN}"'"}}' https://njal.la/api/1/ | sed 's/^.*"id": \([0-9]*\), "name": "_993._tcp.'"${IMAP_HOSTNAME}"'", "type": "TLSA", "content": "[a-z0-9 ]*".*$/\1/g')
      curl -s -H "Accept: application/json" -H "Content-Type: application/json" -H "Authorization: Njalla ${NJALLA_TOKEN}" --data '{"method":"edit-record", "params": {"domain": "'"${SERVER_DOMAIN}"'", "id": '"${RECORD_ID}"', "content": "2 0 1 '"${TLSA_IMAP_RECORD}"'"}}' https://njal.la/api/1/ > /dev/null 2>&1
    fi
  else
    echo "Njal.la domain has already an TLSA record for submission with the right value."
  fi
fi

################ INSTALL APACHE ################
echo "Installing and configuring Apache"
apt install -y apache2 > /dev/null 2>&1
a2enmod brotli expires headers rewrite ssl > /dev/null 2>&1
sed -i 's/\(Listen 80\)/#\1/' /etc/apache2/ports.conf
a2dissite 000-default > /dev/null 2>&1

################ INSTALL PHP ################
echo "Installing and configuring PHP"
apt install -y php libapache2-mod-php php-dom php-mbstring php-intl php-mysql php-zip php-gd php-imagick > /dev/null 2>&1
sed -i 's/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_STRICT/error_reporting E_ALL \& ~E_NOTICE \& ~E_STRICT/' /etc/php/7.4/apache2/php.ini
sed -i 's/;\(mbstring.func_overload = 0\)/\1/' /etc/php/7.4/apache2/php.ini
sed -i 's/;\(pcre.backtrack_limit=\)100000/\1110000/' /etc/php/7.4/apache2/php.ini

################ INSTALL Roundcube ################
echo "Installing and configuring Roundcube"
DEBIAN_FRONTEND=noninteractive apt install -y roundcube > /dev/null 2>&1
sed -i "s/[a-zA-Z0-9]\{16,32\}/$(tr -dc A-Za-z0-9 </dev/urandom | head -c 24 ; echo '')/" /etc/roundcube/config.inc.php
sed -i 's|\(\$config\['"'"'default_host'"'"'\] = '"'"'\)\('"'"';\)|\1ssl://'"${IMAP_HOSTNAME}.${SERVER_DOMAIN}"'\2|' /etc/roundcube/config.inc.php
sed -i 's|\(\$config\['"'"'smtp_server'"'"'\] = '"'"'\)localhost\('"'"';\)|\1tls://'"${SMTP_HOSTNAME}.${SERVER_DOMAIN}"'\2|' /etc/roundcube/config.inc.php
echo '$config['"'"'smtp_auth_type'"'"'] = '"'"'LOGIN'"'"';' >> /etc/roundcube/config.inc.php
cat /etc/apache2/sites-available/default-ssl.conf | grep -vE '^[[:space:]]*$' | grep -vE '^[[:space:]]*#' >> /etc/apache2/sites-available/roundcube.conf
sed -i "s|SSLCertificateFile\t/etc/ssl/certs/ssl-cert-snakeoil.pem|SSLCertificateFile	/etc/letsencrypt/live/${ROUNDCUBE_HOSTNAME}.${SERVER_DOMAIN}/fullchain.pem|" /etc/apache2/sites-available/roundcube.conf
sed -i "s|SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key|SSLCertificateKeyFile /etc/letsencrypt/live/${ROUNDCUBE_HOSTNAME}.${SERVER_DOMAIN}/privkey.pem|" /etc/apache2/sites-available/roundcube.conf
sed -i "s|<VirtualHost _default_:443>|<VirtualHost _default_:443>\n\t\tInclude /etc/roundcube/apache.conf|" /etc/apache2/sites-available/roundcube.conf
sed -i "s|DocumentRoot /var/www/html|DocumentRoot /var/lib/roundcube/public_html|" /etc/apache2/sites-available/roundcube.conf
sudo ufw allow from any to any port 443 proto tcp > /dev/null 2>&1
a2ensite roundcube > /dev/null 2>&1
systemctl restart apache2 > /dev/null 2>&1
