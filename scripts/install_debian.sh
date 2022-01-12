#!/bin/sh
source variables.sh
SERVER_FQDN=$(hostname -f)

# Update Debian
apt update && apt -y upgrade

################ INSTALL UFW ################
apt -y install ufw
ufw enable
ufw logging off

################ INSTALL SUDO ################
apt -y install sudo
echo "$USERNAME  ALL=(ALL) NOPASSWD:ALL"

################ INSTALL SSH ################
apt -y install openssh-server
ufw allow from $IP_CLIENT to any port 22 proto tcp
mkdir /home/$USERNAME/.ssh
echo $SSH_PUBLIC_KEY > /home/$USERNAME/.ssh/authorized_keys
chmod 700 /home/$USERNAME/.ssh
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
sed -i 's/#\(PubkeyAuthentication yes\)/\1/' /etc/ssh/sshd_config
sed -i 's/#\(PasswordAuthentication\) yes/\1 no/'  /etc/ssh/sshd_config
systemctl restart sshd
SSHFP_RECORD="Add the following record to your DNS:\n$(ssh-keygen -r $SERVER_FQDN)"

################ INSTALL MARIADB ################
sudo apt -y install mariadb-server

echo $SSHFP_RECORD
