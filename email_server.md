# Private, Secure emails on 1984 Hosting

## Purpose of this document

The aim of this document is to provide a step by step guide on how to install a mail server on 1984 hosting. This will allow you to have a private and secure email.

There are two reasons for this document to be :

* Let beginners know how to deal with privacy
* As I am not a sys-admin, provide a document that can be edited by anyone if there is any lack of security, or improvement possible.

## Set-up server (before installing mail server)

### Reverse DNS

We will consider that you want to be able to manage emails for the `example.com` domain.

First, you will need to edit the reverse DNS of your server to be `mail.example.com`, this is important to avoid be considered as a spammer by some email servers/clients.

### Debian install

Start by mounting a Debian 11 image on your server, and start the installation using the Qemu console in the Remote access tab.

* First, choose install
* Choose English language
* In country selection, first select `Other`, then `Europe`, and then `Iceland`
* For the keymap, you can continue with the `United States en_US.UTF-8` which is selected by default
* Then select `American english`
* Then, after network configuration fails, choose `Configure network manually`
* For the IP address, select the IP address of your server (you have the data above the Qemu on the right side)
* For netmask, leave `255.255.255.0`
* For gateway, leave the one selected (check it matches the one in the above right)
* For DNS, just copy the two IP in the above right infos, separated by a space
* For hostname, type `mail`
* For domain, type `example.com` (your actual domain of course)
* Choose a root password and confirm it
* Then type the full name of the user you want to create (this will not impact the email configuration, so feel free to put anything you want)
* Then select the username of this account
* And then, type a different password for this user, and confirm it
* Then, select `Manual` partitioning
* Select the `pri/log` line, and type Enter
  * Select `Create a new partition`
  * Choose a size of 5GB
  * Select `Primary`
  * Select `Beginning`
  * Select `Done setting up the partition` and type Enter
* Select the `pri/log` line again, and type Enter
  * Select `Create a new partition`
  * Choose a size which match your RAM size, for example, if you have 1GB of ram, choose a size of 1GB.
  * Select `Primary`
  * Select `Beginning`
  * Select the line `Use as` and type Enter
  * Choose `swap area`
  * Select `Done setting up the partition` and type Enter
* Select `Finish partitioning and write changes to disk` and type Enter
* Select `<Yes>` and type Enter
* Select `<No>` on the Configure package manager screen and type Enter
* Select `United Kingdom`, which is a good choice for Iceland, and type Enter
* Choose `deb.debian.org` and type Enter
* Type `Tab` to select `Continue` and type Enter
* Choose whether you want to participate in package survey with tab, and type Enter when your answer is selected
* Unselect all the selected elements, by typing on the Space bar on the ones selected (with a `*` on it). You should have no one selected before continuing. Then select `<Continue>` and type Enter
* Select `<Yes>` to install GRUB and type Enter
* Choose the second option with the name of your disk, and type Enter
* Installation is complete. Instead of clicking on `<Continue>`, you can unmount the disk image from the top menu, which will also reboot the server.

After the boot, login as root on your server.

### Install firewall

Let's install `ufw`, and set rules to `reject` all incoming traffic.

```
apt -y install ufw
```

Then, enable the firewall and update the rules

```
ufw enable
ufw default deny incoming
ufw default deny outgoing
```

### Install SSH (1st pass)

Qemu is nice, but let's jump to something more useful. Install SSH by running the following command:

```
apt install -y ssh
```

If the above command worked, please check again that you set up the firewall correctly, All outgoing traffic should be denied, so the above command should not be working.

First problem is that apt is not able to resolve deb.debian.org, let's solve it by typing the two following commands (replace the IP by the IP address of your DNS server)

```
ufw allow out to 93.95.224.28 proto udp port 53
ufw allow out to 93.95.224.29 proto udp port 53
```

Now, we can resolve deb.debian.org :

```
ping deb.debian.org
```

This will produce the following result :

```
PING debian.map.fastlydns.net (199.232.150.132) 56(84) bytes of data
```

Let's now add a rule to allow outgoing traffic on port 80 for this IP address:

```
ufw allow out to 199.232.150.132 proto tcp port 80
```

> **IMPORTANT NOTE**
>
>  The IP address of `deb.debian.org` may change, resulting in apt not being able to get packages. For now, this is not a problem, as if apt is not working later, this won't prevent our server from working.

Now you can install ssh:

```
apt install -y ssh
```

Of course, you won't be able to access SSH due to the firewall rules. We strongly discourage you to make the port 22 open to the world. Two solutions:

* The one I'm using : connect to the internet through a VPN, so you are guaranteed to have a static IP address
* Be ready to update the rules if your IP address changes

```
ufw allow from [YOUR_PERSONAL_PUBLIC_IP] proto tcp to any port 22
```

Then, try to connect through SSH to your server to check if it works.

Now that it works, we should not leave root connected in the Qemu emulator. Type the following command :

```
exit
```

If you didn't do it before, generate an SSH key with the following command:

```
ssh-keygen -C "your_email@example.com"
```

> **IMPORTANT NOTE**
>
> In the next steps of this tutorial, we will make the user owning this key able to access the server with root privileges using this key only. If you don't set a password, it means that anybody with your key (a session left unlocked on computer? ;-)) will be able to access your server with root privileges without password. We then strongly encourage you to set a passphrase

Now connect to the server through SSH, using the user you created in debian, typing the password you set for this user at the installation step _(You won't be able to connect as root to the server through SSH)_

```
ssh user@mail.example.com
```

Now, you can connect as root, using the following command :

```
su
```

### Install sudo

Of course, we just connected as root on SSH, which is something we want to avoid. Now as root, type the following command :

```
apt install -y sudo
```

And now, let's add our user to the sudo users:

```
sudo visudo
```

Then, add the following line at the end of the file.

```
# Add user to sudoers
username  ALL=(ALL) NOPASSWD:ALL
```

This will allow you to have the sudo privileges with your user without the interface prompting you for the user password.

You can now type the following command to go back to the original user:

```
exit
```

Then, all you have to do is to check that you have the sudo rights.

```
sudo systemctl restart ufw
```

If this command produces no output and does not prompt for your password, then everything is fine.

### Setup SSH (2nd and almost last pass)

Now, let's remove the use of a password to connect through SSH and use our SSH key instead. From an other terminal on your machine, run the following command _(`username` refers to the username on the server)_:

```
scp ~/.ssh/id_rsa.pub username@mail.example.com:/home/username
```

Now, add this key to the authorized keys SSH, by executing the following command on the server:

```
mkdir ~/.ssh
chmod 700 ~/.ssh
cp ~/id_rsa.pub ~/.ssh/id_rsa.pub
mv ~/id_rsa.pub ~/.ssh/authorized_keys
```

Now, type the following command to exit SSH :

```
exit
```

And try to connect again to SSH, it should not ask for your users password (but asks for your SSH key password instead):

```
ssh username@mail.example.com
```

Now that it is working, let's remove the possibility to connect using the user's password through SSH:

```
sudo nano /etc/ssh/sshd_config
```

Look for the line containing `#PasswordAuthentication yes` (use `Ctrl+W` shortcut). Remove the `#` prefix, and replace yes by no. Then save (`Ctrl+O`) and exit (`Ctrl+X`).

And then restart the SSH service :

```
sudo systemctl restart sshd
```

### Setup encrypted partition

Now, we will use the space remaining unpartitioned in our server to mount an encrypted partition on it.

Whether the disk get accessed from somewhere, no information can be retrieved from it.

Let's first install cryptsetup :

```
sudo apt -y install cryptsetup
```

Now, let's create a partition using fdisk. First, get the name of your disk by using the following command :

```
sudo fdisk -l
```

The response to this command will start with a line like this:

```
Disk /dev/vda: 80 GiB, 85899345920 bytes, 167772160 sectors
```

Then, you know the disk name is `dev/vda`.

Now, let's create a partition:

```
sudo fdisk /dev/vda
```

First, let's see the free storage, by typing the `F` command, followed by Enter. This will produce a result similar to this:

```
Unpartitioned space /dev/vda: 71.62 GiB, 76899418112 bytes, 150194176 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes

   Start       End   Sectors  Size
17577984 167772159 150194176 71.6G
```

Now, let's create a new partition with the `n` command.

* Type `p` to choose a primary partition
* Let's type nothing and keep the default partition number
* Let's keep first and last sector automatic as well

Now type the `p` command to check that everything is fine. Please keep note of the number of the new created partition.

Now, type the `w` command to write the changes to the disk. This will exit fdisk as well.

```
sudo cryptsetup luksFormat /dev/vda3
```

Type `YES` when it says it will erase all the data.

Now, choose a passphrase that will be needed to decrypt the volume. Then confirm it.

Time to open the disk now:

```
sudo cryptsetup open /dev/vda3 encrypted
```

Let's format it as ext4:

```
sudo mkfs.ext4 /dev/mapper/encrypted
```

Now, let's try to mount it:

```
sudo mkdir /data
sudo mount -t ext4 /dev/mapper/encrypted /data
sudo ls /data
```

This should produce the following result:

```
lost+found
```

OK, last but not least, what we want now is to be able to mount the partition when the system boots.

Let's first add our partition to fstab :

```
sudo nano /etc/fstab
```

Then add the following line at the end of the file

```
/dev/mapper/encrypted      /data                 ext4    defaults        0 0
```

Now, let's try to unmount it, and mount it again to be sure it works:

```
sudo umount /data
ls /data
sudo mount /data
ls /data
```

The first `ls` should produce no result, and the second should produce the `lost+found` result.

So now, fstab is able to mount our encrypted partition **once it is open**. So now, let's open the partition at startup. For this, we have two choices :
* Ask for password after reboot, this is by far the most secure, but it is less safe as if your server reboots unexpectedly, it needs a manual intervention to decrypt the disk
* Use a key file, which is less secure, but safer, as it does not need any manual intervention to mount the disk

In this tutorial, we will use the first method, for a simple reason. Everything is on the same physical disk. If we want to hide from somebody who would have access to the disk, then the key will be unencrypted on the same disk. It would be then meaningless to try to hide from somebody with an access to the disk.

So in order to open the disk when the system boots, just run the following command :

```
sudo nano /etc/crypttab
```

Then add the following line at the end of the file:

```
encrypted  /dev/vda3       none
```

It's now time to reboot the server with the following command :

```
sudo shutdown -r now
```

If you go now to Qemu in the 1984 dashboard, you can see that it requires the passphrase to decrypt the disk:

```
Please enter passphrase for disk encrypted on /data
```

Enter the passphrase, and then, you can connect to SSH again.

### Change home directory

Everything which is now on the unencrypted disk can be considered as Open Source, as you're following this tutorial which is published online. Everything except one file : the SSH public key.

Let's be clear about it, the SSH public key on the unencrypted disk is absolutely not a problem at all for security. If anyone can access it, they can't do anything... except read it.

And this is a privacy issue. Your public key may be shared to some places, when it is linked to you. Meaning that if some investigation let investigators access your public key which may be stored on GitHub, then is able to link it to your identity, and then can access this public key, they have a strong proof that this server belongs to you.

So let's move the public key to our encrypted disk.

To make it easier and even more private, let's move the whole home folder of the user to the /data disk.

```
sudo mkdir /data/username
sudo cp -r /home/username /data/username
sudo chown -R username /data/username
```

Now, let's change the home directory of the user. In order to do so, you need to close your SSH session, log in as root on the Qemu, and run the following command:

```
usermod -d /data/username username
rm -rf /home/username
```

Don't forget to close the session on Qemu:

```
exit
```

Now, you can connect again to SSH, and run the following command:

```
cd ~ && pwd
```

The result should be `/data/username`. Now that the user has the sudo power, and that his home folder has been set, we definitely don't need to be root anymore. So let's change the `root` password to something nobody will know:

```
sudo usermod --password 123 root
```

Now, nobody knows root's password.

We could also do the same for the current user, but it is a choice you have to make:

* You are absolutely sure that the IP set in ufw rules will be up, and available to connect to the machine. Then you can do it.
* You want to change your ufw rule to allow everybody on port 22, this sounds less secure to me

Remember that is you do that for the current user, then you have no backup to be able to access your server. Of course, you can reinstall the system from scratch, without losing your data partition, but it all depends on what you're up to.

Here is the command, I'm not formatting it, in order to not let people reading only commands do this without knowing the risks:

usermod --password 123 username

Once done, it's now time to install the mail server itself.

## Install mail server

### MariaDB

As we want to be managing virtual users, we need MariaDB to store the mailboxes configuration:

```
sudo apt install -y mariadb-server
```

Now, let's secure our database:

```
sudo mysql_secure_installation
```

* Type Enter for the root password, as there is no root password
* Then type `Y` to choose unix_socket authentication
* Then type `Y` to change the root password
* Type the root password and confirm
* Then type `Y` to remove anonymous user
* Then type `Y` to disallow root login remotely
* Then type `Y` to remove test databaseand access to it
* Finally, type `Y` to reload privileges

Now, we will store the database data to the `/data` folder. First, let's copy the folder containing all the data:

```
sudo cp -r /var/lib/mysql /data/mysql
```

Now, let's edit the configuration file to let MariaDB know where the data are stored:

```
sudo nano /etc/mysql/mariadb.conf.d/50-server.cnf
```

Find the line starting with datadir, and replace its value by `/data/mysql`:

```
basedir                 = /usr
datadir                 = /data/mysql
tmpdir                  = /tmp
```

Save and close the file. Then let the mysql user access the data:

```
sudo chown -R mysql:mysql /data/mysql
```

And restart the server:

```
sudo systemctl restart mysql
```

You can now safely remove the previous folder:

```
sudo rm -r /var/lib/mysql
```

Now, let's create a script to add a database for postfix and a dedicated user with privileges on it (Replace passwd by the actual passwd you want for that user in the below command):

```
cat > ~/create.sql << EOF
CREATE DATABASE postfix;
GRANT ALL PRIVILEGES ON postfix.* TO "mail"@"localhost" IDENTIFIED BY "passwd";
FLUSH PRIVILEGES;
EOF
```

Now, run the file on the server :

```
mysql -u root -p < ~/create.sql
```

Now, let's add a script to create the config we want:

```
cat > ~/postfix-mysql.sql << EOF
# Based on http://flurdy.com/docs/postfix/#config-simple-database

USE postfix;

CREATE TABLE aliases (
 pkid smallint(3) NOT NULL auto_increment,
 mail varchar(120) NOT NULL default '',
 destination varchar(120) NOT NULL default '',
 enabled tinyint(1) NOT NULL default '1',
 PRIMARY KEY  (pkid),
 UNIQUE KEY mail (mail)
);

CREATE TABLE domains (
 pkid smallint(6) NOT NULL auto_increment,
 domain varchar(120) NOT NULL default '',
 transport varchar(120) NOT NULL default 'virtual:',
 enabled tinyint(1) NOT NULL default '1',
 PRIMARY KEY  (pkid)
);

CREATE TABLE users (
 id varchar(128) NOT NULL default '',
 name varchar(128) NOT NULL default '',
 uid smallint(5) unsigned NOT NULL default '5000',
 gid smallint(5) unsigned NOT NULL default '5000',
 home varchar(255) NOT NULL default '/data/mail/virtual',
 maildir varchar(255) NOT NULL default 'blah/',
 enabled tinyint(1) NOT NULL default '1',
 change_password tinyint(1) NOT NULL default '1',
 clear varchar(128) NOT NULL default 'changemepls',
 crypt varchar(128) NOT NULL default 'V2VkIE9jdCAyOSAxMzo1MD',
 quota varchar(255) NOT NULL default '',
 PRIMARY KEY  (id),
 UNIQUE KEY id (id)
);
EOF
```

And then run it:

```
mysql -u mail -p < ~/postfix-mysql.sql
```

That's all for the database.

### Postfix

Let's start by installing postfix:

```
sudo apt -y install postfix postfix-mysql
```

When prompted, select `Internet Site` type of install. Keep the value for the domain.

Let's now do some operations for the folders setup:

```
sudo mkdir /data/mail
sudo cp /etc/aliases /data/mail/aliases
sudo postalias /data/mail/aliases
sudo mkdir /data/mail/virtual
sudo groupadd --system virtual -g 5000
sudo useradd --system virtual -u 5000 -g 5000
sudo chown -R virtual:virtual /data/mail/virtual
```

Now, let's add the MySQL configuration for Postfix. As this config will contain the credentials for the database, it's better to keep them in the encrypted drive:

```
sudo mkdir /data/postfix
sudo chmod 755 /data/postfix
```

Now, it's time to edit the main configuration file of Postfix. First, let's configure the virtual accounts:

```
echo '# this specifies where the virtual mailbox folders will be located
virtual_mailbox_base = /data/mail/virtual
# this is for the mailbox location for each user
virtual_mailbox_maps = mysql:/data/postfix/mysql_mailbox.cf
# and this is for aliases
virtual_alias_maps = mysql:/data/postfix/mysql_alias.cf
# and this is for domain lookups
virtual_mailbox_domains = mysql:/data/postfix/mysql_domains.cf

virtual_uid_maps = static:5000
virtual_gid_maps = static:5000' | sudo tee -a /etc/postfix/main.cf

# Will be using virtual domains
local_recipient_maps =
```

Now, let's create our config files. Replace passwd by the actual password of your mysql user:

```
cat << EOF | sudo tee -a /data/postfix/mysql_mailbox.cf
user=mail
password=passwd
dbname=postfix
table=users
select_field=maildir
where_field=id
hosts=127.0.0.1
additional_conditions = and enabled = 1
EOF
```

```
cat << EOF | sudo tee -a /data/postfix/mysql_alias.cf
user=mail
password=passwd
dbname=postfix
table=aliases
select_field=destination
where_field=mail
hosts=127.0.0.1
additional_conditions = and enabled = 1
EOF
```

```
cat << EOF | sudo tee -a /data/postfix/mysql_domains.cf
user=mail
password=passwd
dbname=postfix
table=domains
select_field=domain
where_field=domain
hosts=127.0.0.1
additional_conditions = and enabled = 1
EOF
```

For the same reason (because they contain credentials), let's handle the permissions:

```
sudo chown root:postfix /data/postfix/mysql_*
sudo chmod 0640 /data/postfix/mysql_*
```

### MySQL again

It's now time to add the domain we will handle and the required and first users.

```
cat > ~/required.sql << EOF
USE postfix;

INSERT INTO domains (domain) VALUES ('localhost'), ('localhost.localdomain');

INSERT INTO aliases (mail,destination) VALUES
 ('postmaster@localhost','root@localhost'),
 ('sysadmin@localhost','root@localhost'),
 ('webmaster@localhost','root@localhost'),
 ('abuse@localhost','root@localhost'),
 ('root@localhost','root@localhost'),
 ('@localhost','root@localhost'),
 ('@localhost.localdomain','@localhost');

INSERT INTO users (id,name,maildir,crypt) VALUES
 ('root@localhost','root','root/',encrypt('rootpasswd', CONCAT('$5$', MD5(RAND()))) );
EOF
```

Then execute it:

```
mysql -u mail -p < ~/required.sql
```

Now, time to insert the domain we want to handle:

```
mysql -u mail -p postfix -e "INSERT INTO domains (domain) VALUES ('example.com');"
```

And the user we want to add:

```
mysql -u mail -p postfix -e "INSERT INTO users (id,name,maildir,crypt) VALUES ('somename@example.com','Full name','somename/',encrypt('passwd', CONCAT('$5$', MD5(RAND()))) );"
```

Now we can restart Postfix:

```
sudo systemctl restart postfix
```

### Testing mail server

Now, Postfix is somehow working. It means that you can receive and send messages to the world, in theory (in fact, most of emails providers will reject communication over STARTTLS without a valid certificate, and will reject emails with no SPF signature). But at least, let's try to use it to see if it works.

First, let's authorize SMTP connection from our client only:

```
sudo ufw allow from [YOUR_PERSONAL_PUBLIC_IP] proto tcp to any port 25
```

And now, on your personal machine, run :

```
telnet mail.example.com 25
```

> _Please remember that 99% of issues now are related to firewall. It can be firewall of your machine, or the firewall of your ISP, or the firewall of your VPN. As the SMTP port is used as an SMTP relay, many blocks this port to prevent user from sending spams._

If you can connect, run the following commands on the server. First, let's say hello.

```
helo mail.example.com
```

Then, set the sender of the email:

```
mail from: root@localhost
```

Then the recipient :

```
rcpt to: username@example.com
```

And now, the data of the email:

```
Subject: This is a test email
Here is my test
```

And now, let's end with a dot to tell that data is over:

```
.
```

Finally, close the connection:

```
quit
```

And that's all, you sent the first email to your machine. It's now time to see if it worked:

```
ssh username@mail.example.com
```

And then, read your email :

```
sudo ls /data/mail/virtual/username/new/
```

You should have a file listed. Then :

```
sudo cat /data/mail/virtual/username/new/[filename]
```

Be careful, it may take some time to arrive. Now, you can remove the `ufw` rule on port 25.

### SSL with Letsencrypt

It's now time to add more security implementing STARTTLS with an recognized SSL certificate. We will use the Let's encrypt service to do so.

Let's first install it:

```
sudo apt -y install certbot
```

Now, let's run the commmand to generate a certificate. As it will require access to the 443 port, we will run it as three separated commands, so the port will not stay open for long. Replace mail.example.com by your actual domain in the command below:

```
sudo ufw allow out to any port 443 proto tcp && sudo ufw allow from any to any port 80 proto tcp && sudo certbot certonly --standalone -d mail.example.com ; sudo ufw delete allow out to any port 443 proto tcp ; sudo ufw delete allow from any to any port 80 proto tcp
```

Now that you have your key, you should keep in mind that it will expire after 90 days. So we would like to renew it automatically when the certiciate is about to expire. And there is two cases for it:
* You can live the port 80 open on the machine, and let letsencrypt do the rest
* You have to run your own cron job, in order to renew certificates

For security reasons, we don't want to live any port we don't use open, so we will run our own script.

First, we need to write a script in order to renew the certificate :

```
cat > ~/renew_certbot_certificate.sh << EOF
ufw allow out to any port 443,80 proto tcp
ufw allow from any to any port 80 proto tcp
certbot renew --force-renewal
ufw delete allow out to any port 443,80 proto tcp
ufw delete allow from any to any port 80 proto tcp
EOF
```

Then make this script able to be executed :

```
chmod +x ~/renew_certbot_certificate.sh
```

And then run it to ensure there is no error:

```
sudo ~/renew_certbot_certificate.sh
```

Now that everything is working fine, we need to edit our script. We just forced renewal in the script, to ensure that everything is working fine. Letsencrypt is free, but it does not mean that it is costless. That's why we should never renew certificate more frequently than necessary. So let's not force the renewal:

```
sed -i 's/ --force-renewal//' ~/renew_certbot_certificate.sh
```

You can now safely run the script again, and ensure that the certificate is not renewed:

```
sudo ~/renew_certbot_certificate.sh
```

You should get the following result when running this command:

```
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
The following certificates are not due for renewal yet:
  /etc/letsencrypt/live/mail.example/fullchain.pem expires on 2022-03-28 (skipped)
No renewals were attempted.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

Letsencrypt will renew the certificate if they will expire in less than 30 days. You can run it everyday if the certificate renewal is critical for you, or we can run it weekly, that's the solution we choose here.

```
sudo mv ~/renew_certbot_certificate.sh /etc/cron.weekly
```

Now, letsencrypt will check for certificate renewal every week.

### SSL with Postfix

Now that we have a valid SSL certificate which will renew automatically, let's add it to Postfix, and make it an SSL only SMTP server.

First let's replace the path of the certificate:
```
sudo sed -i 's|smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem|smtpd_tls_cert_file=/etc/letsencrypt/live/mail.gahfy.io/cert.pem|' /etc/postfix/main.cf
```

Then the path of the key:
```
sudo sed -i 's|smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key|smtpd_tls_key_file=/etc/letsencrypt/live/mail.gahfy.io/privkey.pem|' /etc/postfix/main.cf
```

Now it's time to restart postfix before testing it again:

```
sudo systemctl restart postfix
```

Now, we can safely open port 25 to all traffic, as it is the purpose of the mail relay:

```
sudo ufw allow from any proto tcp to any port 25
```

It's now time to check if starttls is working fine from your machine:

```
openssl s_client -connect mail.example.com:25 -starttls smtp
```

This will connect you using the starttls protocol. Now let's try same as before, to send an email with the following commands, to type one at a time:

```
helo mail.example.com
mail from: root@localhost
rcpt to: username@example.com
data
Subject: Test with STARTTLS
Here is my test with STARTTLS
.
quit
```

Now check your `/data/mail/virtual/username/new` folder to check if you received the mail you just sent.

### Force STARTTLS for relay and submission

Our server is now implementing STARTTLS, but it does not require to use it. So what we want to do is to allow communication only using STARTTLS. 

Let's do this.

First, let's remove SMTP on `/etc/postfix/master.cf` :

```
sudo sed -i 's/\(smtp      inet  n       -       y       -       -       smtpd\)/#\1/' /etc/postfix/master.cf
```

Then, enable submission:

```
sudo sed -i 's/#\(submission inet n       -       y       -       -       smtpd\)/\1/' /etc/postfix/master.cf
```

## Avoid being considered as spammer

### BATV

### SPF

### DKIM

### Autodiscover

### With great power

Use email reasonably
