# Install Postfix

Now time to install a mail server. For the SMTP part, we will use Postfix.

## MySQL configuration

Postfix will retrieve our users from a MariaDB database. That's why we need to create a dedicated database, and a dedicated user who will have privileges on that database.

So first, we need to add that user to MariaDB with the following command:

```
mysql -u root -p
```

Then, type your password, and type the following command in MySQL:

```
CREATE DATABASE postfix;
GRANT ALL PRIVILEGES ON postfix.* to 'mail'@'localhost' IDENTIFIED BY 'password';
FLUSH PRIVILEGES;
QUIT;
```

Now that your database and user are created, let's populate it:

```
mysql -u mail -p
```

Then, type the password you set for the mail user, and then, type the following commands in mysql:

```
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

QUIT;
```

All is now done on the SQL part.

## Install Postfix

As usual, it all starts with an apt command:

```
sudo apt -y install postfix postfix-mysql
```

Choose `Internet Site` when you are prompted for it.
Keep the `System mail name` by default.

## Configure folders

Let's now make the folders that Postfix will need for emails:

```
sudo cp /etc/aliases /etc/postfix/aliases
sudo postalias /etc/postfix/aliases
sudo mkdir -p /data/mail/virtual
sudo groupadd --system virtual -g 5000
sudo useradd --system virtual -u 5000 -g 5000
sudo chown -R virtual:virtual /data/mail/virtual
```

## Configure Basic Postfix

First, let's uncomment the generation of warnings:

```
sudo sed -i 's/#\(delay_warning_time = 4h\)/\1/' /etc/postfix/main.cf
```

Then change the alias folder:

```
sudo sed -i 's|alias_maps = hash:/etc/aliases|alias_maps = hash:/etc/postfix/aliases|' /etc/postfix/main.cf
sudo sed -i 's|alias_database = hash:/etc/aliases|alias_database = hash:/etc/postfix/aliases|' /etc/postfix/main.cf
```

Then add the path to the folder containing virtual mailboxes:

```
echo 'virtual_mailbox_base = /data/mail/virtual' | sudo tee -a /etc/postfix/main.cf
```

And then the path to the MySQL configuration files:

```
echo 'virtual_mailbox_maps = mysql:/etc/postfix/mysql_mailbox.cf' | sudo tee -a /etc/postfix/main.cf
echo 'virtual_alias_maps = mysql:/etc/postfix/mysql_alias.cf' | sudo tee -a /etc/postfix/main.cf
echo 'virtual_mailbox_domains = mysql:/etc/postfix/mysql_domains.cf' | sudo tee -a /etc/postfix/main.cf
```

Now the groups and the user mapping for virtual mailboxes:

```
echo 'virtual_uid_maps = static:5000' | sudo tee -a /etc/postfix/main.cf
echo 'virtual_gid_maps = static:5000' | sudo tee -a /etc/postfix/main.cf
```

Now, specify that we will use virtual domains only:

```
echo 'local_recipient_maps = ' | sudo tee -a /etc/postfix/main.cf
sudo sed -i 's/mydestination =.*/mydestination =/' /etc/postfix/main.cf
```

## Postfix MySQL configuration

As we added the paths to the MySQL configuration files, we now need to create those files:

```
cat << EOF | sudo tee -a /etc/postfix/mysql_mailbox.cf
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
cat << EOF | sudo tee -a /etc/postfix/mysql_alias.cf
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
cat << EOF | sudo tee -a /etc/postfix/mysql_domains.cf
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

As you can see, those files contains the username and password to access database as `mail` user. Let's add stronger restrictions to those files:

```
sudo chown root:postfix /etc/postfix/mysql_*
sudo chmod 0640 /etc/postfix/mysql_*
```

## Add users to MySQL

It's now time to add the postfix users to MySQL:

```
mysql -u mail -p
```

And then, run the following command:

```
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
```

Then, add the domain you want to manage

```
INSERT INTO domains (domain) VALUES ('example.com');
```

Finally, add the virtual user (Change the password by the one you actually want):

```
INSERT INTO users (id,name,maildir,crypt) VALUES ('johndoe@example.com','John Doe','jdoe/',encrypt('password', CONCAT('$5$', MD5(RAND()))) );
```

And finally, quit MySQL:

```
QUIT;
```

## Secure Postfix installation

Our current installation allows to use SMTP on port 25, without using STARTTLS. This is not something which is ideal, but it's a choice we have made to ensure that anynody can send email to your mailbox. Forcing STARTTLS on port 25 may result in some rare email servers unable to send emails to you, resulting so in some emails not being delivered to you.

For email, my consideration is that reliability is the most important, and then security and privacy comes. That's why we will keep it like this.

Right now, it is also possible for you to login without using STARTTLS on port 25. And actually, the world will be able to try to log in that way. We definitely don't want this to be available. I know, you think you may know what you're doing, but you may try some nice email clients without checking the specification well, or you may be tempted to try telnet your server some time to be sure everything is allright... And also, we definitely don't want the world to be able to try logging in on port 25.

That's why, what we will do is:
* Enable port 25, allow STARTTLS without forcing it, for incoming emails only
* Enable port 465, which is SMTP SSL port, for incoming emails only
* Enable port 587, only for some IP, only allowing TLS, which will allow the user to authenticate and send messages

### Secure cleartext transactions

First, let's disable authentication from port 25:

```
sudo sed -i 's/permit_sasl_authenticated //' /etc/postfix/main.cf
```

Then restart your postfix server:

```
sudo systemctl restart postfix
```

And you can now open the 25 port to the world:

```
sudo ufw allow from any to any port 25
```

And now, you can try from any client, using telnet:

```
telnet your_ip 25
```

Then, type those commands, one after the other:

```
ehlo your_server_fqdn
```

Then, authenticate

```
AUTH LOGIN
```

You should get the following error:

```
503 5.5.1 Error: authentication not enable
```

Now, let's try to send an email to your email address (change johndoe@example.com by the email you configured earlier):

```
MAIL FROM: root@localhost
RCPT TO: johndoe@example.com
DATA
Here is my test email
.
quit
```

Now, time to check on your server (replace jdoe by the actual folder you configured earlier):

```
sudo ls -al /data/mail/virtual/jdoe/new
```

You should see the email. Now, just check the content (replace jdoe and filename):

```
sudo cat /data/mail/virtual/jdoe/new/filename
```

You should see the content of the email you just sent. So from now on, people can send you emails.

### STARTTLS

STARTTLS is already implemented, but implemented with a self-signed certificate. This has two major issues:

* Even if the certificate is valid for 10 years, you still have to remember to renew it, it's not done automatically
* Some very rare mail servers (I don't know any) may reject incoming emails from server with a not recognized SSL certificate

That's why we will use an SSL certificate which will be coming from a trusted authority, and which will be renewed automatically.
In order to keep this free, we will use Let's encrypt which allows us to have both issues fixed for free.

```
sudo apt -y install certbot
```

Before thinking about SSL generation, certbot needs the port 80 to be open:

```
sudo ufw allow from any to any port 80
```

It's now time to generate your certificate. Before starting it, just think a little bit about domains.
If you started from the beginning, you should have your server FQDN set to ip-1-2-3-4.domain.com, which matches the reverse DNS for the IP address of the server.

But you don't want to have this domain as the MX record for your domain. First, it does not look nice ;-). Now stop kidding, if you do so, it will prevent you from switching mail server easily. You want instead to have an CNAME (like smtp) pointing to that A record. Then, if you want to change mail server, you will only have to change this CNAME record.

What we want now is to create an SSL certificate for that CNAME domain, so for smtp.example.com instead of ip-1-2-3-4.example.com.

Just be sure you registered the CNAME record in your DNS, and then run the following command:

```
sudo certbot certonly --standalone
```

Enter your email address, then accept the terms, then decide whether you allow share of your email address with EFF or not, and then, typed your domain name, like `smtp.example.com`.
Your certificate should now be available. Let's check it:

```
sudo ls /etc/letsencrypt/live/smtp.example.com
```

If you can find those certificates, congratulations. It's now time to tell Postfix to use those certificates (replace the domain name in the two commands):

```
sudo sed -i 's|smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem|smtpd_tls_cert_file=/etc/letsencrypt/live/smtp.example.com/cert.pem|' /etc/postfix/main.cf
sudo sed -i 's|smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key|smtpd_tls_key_file=/etc/letsencrypt/live/smtp.example.com/privkey.pem|' /etc/postfix/main.cf
```

Now, you can restart Postfix:

```
sudo systemctl restart postfix
```

Now, you can try STARTTLS on your server by running the following command on your machine:

```
openssl s_client -starttls smtp -connect smtp.example.com:25
```

The last line of the certificate part should be:

```
Verify return code: 0 (ok)
```

### SSL

Let's now turn on SMTP over SSL on port 465. As we said previously, we don't want to allow authentication on this port as it will be world readable.

First, let's enable SMTPS:

```
sudo sed -i 's/#\(smtps     inet  n       -       y       -       -       smtpd\)/\1/' /etc/postfix/master.cf
```

Then, specify that it is a TLS protocol:

```
sudo sed -i 's/#\(  -o smtpd_tls_wrappermode=yes\)/\1/' /etc/postfix/master.cf
```

Then, disable authentication on that port:

```
sudo sed -i ':a;N;$!ba;s/#\(  -o smtpd_sasl_auth_enable=\)yes/\1no/2' /etc/postfix/master.cf
```

And finally, allow relay on this port for local addresses:

```
sudo sed -i ':a;N;$!ba;s/#\(  -o smtpd_relay_restrictions=\)permit_sasl_authenticated,reject/\1permit_mynetworks,reject/2' /etc/postfix/master.cf
```

And you can now restart postfix:

```
sudo systemctl restart postfix
```

Finally, open the 465 port:

```
sudo ufw allow from any to any port 465
```

And you have now a fully operational SMTP server for receiving emails.

### TLS security

OK, there is somthing I didn't tell you. SMTP servers will not check that your SSL certificate is valid or not (at least more than 99% of them won't) so this means that they may be able to a Man-In-The-Middle attack, resulting in an attacker getting your emails. We can definitely secure this with a DANE record.

_First of all, you need to have DNSSEC enabled for your domain name_

#### Add Dane-TLSA record

A TLSA record is a DNS record that allows clients communicating with your server to authenticate your SSL certificate. You can put a fingerprint of your certificate in the record to do so, but as our certificate will be renewed every 2 months, this will make the record be not valid after 2 months.

What we can do instead is tell in our DNS record what authority is issuing our certificate. Then, if our certificate is issued by that authority, the client will consider it as valid.

As we trust Let's Encrypt to not provide an SSL certificate to an illegitimate service, we can do so.

So you need to create a TLSA record in your DNS, with the following content:

```
2 0 1 6d99fb265eb1c5b3744765fcbc648f3cd8e1bffafdc4c2f99b9d47cf7ff1c24f
```

The name of that record will be `_25._tcp.smtp` (replace smtp by your subdomain if you use an other one). Add the same content to a record named `_465._tcp.smtp`. Then now, when a server will connect to one or the other of the ports, it can trust the certificate. Finally, you can add a third one, with the same value, and with the name `_587._tcp.smtp` to prepare for submission.

So you now have a fully operational, secure and private mail server that can receive email.

### Submission

#### Postfix

Now, it's time to receive emails. Actually, everything is almost done, so we won't have much to do. First of all, let's enable submission:

```
sudo sed -i 's/#\(submission inet n       -       y       -       -       smtpd\)/\1/' /etc/postfix/master.cf
```

And then, specify this configuration in the submission part of `/etc/postfix/master.cf`
```
-o smtpd_tls_security_level=encrypt
-o smtpd_sasl_auth_enable=yes
-o smtpd_tls_auth_only=yes
#  -o smtpd_reject_unlisted_recipient=no
-o smtpd_client_restrictions=permit_sasl_authenticated,reject
-o smtpd_relay_restrictions=permit_sasl_authenticated,reject
```

Now, you can restart Postfix:

```
sudo systemctl restart postfix
```

Submission will run on port 587, so you have to open this port.  We strongly encourage you to use a VPN, then you can open the port to the VPN address only:

```
sudo ufw allow from 1.2.3.4 to any port 587
```

If you don't want to use a VPN, then you can use the following command to open port 587 to the world:

```
sudo ufw allow from any to any port 587
```

And that's it, you're Postfix is now fully configured.

#### SASL

Of course, we need to install and configure SASL to allow authenticated users:

```
sudo apt install -y libsasl2-modules libsasl2-modules-sql libgsasl7 libauthen-sasl-cyrus-perl sasl2-bin libpam-mysql
```

Then, add the user and folder:

```
sudo adduser postfix sasl
sudo mkdir -p /var/spool/postfix/var/run/saslauthd
```

Then add configuration to main postfix configuration file:

```
echo 'smtpd_sasl_auth_enable = yes
broken_sasl_auth_clients = no
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain =' | sudo tee -a /etc/postfix/main.cf
```

Then configure SASL auth deamon:

```
sudo sed -i 's/START=no/START=yes/' /etc/default/saslauthd
sudo sed -i 's|OPTIONS="-c -m /var/run/saslauthd"|OPTIONS="-r -c -m /var/spool/postfix/var/run/saslauthd"|' /etc/default/saslauthd
```

Now, tell Postfix how to interact with SASL:

```
echo $'pwcheck_method: saslauthd
mech_list: plain login cram-md5 digest-md5
log_level: 7
allow_plaintext: true
auxprop_plugin: sql
sql_engine: mysql
sql_hostnames: 127.0.0.1
sql_user: mail
sql_passwd: passwd
sql_database: postfix
sql_select: select crypt from users where id=\'%u@%r\' and enabled = 1' | sudo tee -a /etc/postfix/sasl/smtpd.conf
```

```
echo 'auth required pam_mysql.so user=mail passwd=passwd host=127.0.0.1 db=postfix table=users usercolumn=id passwdcolumn=crypt crypt=1
account sufficient pam_mysql.so user=mail passwd=passwd host=127.0.0.1 db=postfix table=users usercolumn=id passwdcolumn=crypt crypt=1' | sudo tee -a /etc/pam.d/smtp
```

And then, restart services:

```
sudo systemctl restart saslauthd
sudo systemctl restart postfix
```
#### DNS

You can try to send emails from now using your SMTP server, but the chances are high that your email won't pass spam filters. So we need to implement some features.

##### SPF Record

SPF record is required by many providers. To give you an example, gmail won't let you send emails to their users if you don't have this record on your domain. It is here to tell who is able with your domain. Here are two useful configuration:

```
v=spf1 ip4:1.2.3.4 -all
```
_This configuration will allow only the given IP address to be considered as legitimate sender for emails of that domain_

```
v=spf1 mx -all
```
_This configuration will allow only the MX servers of the domain to be considered as legitimate sender for emails of that comain_

As I am using the same server for receiving and sending emails, the last one is the one I prefer.

##### DKIM record

SPF specifies who is allowed to send email for your somain. DKIM is here to provide a signature for your email domain. As usually, it all starts with an apt command:

```
sudo apt install -y opendkim opendkim-tools
```

Then add and change some configuration with the following command:

```
echo 'AutoRestart             Yes
AutoRestartRate         10/1h' | sudo tee -a /etc/opendkim.conf
```

```
sudo sed -i 's/UMask\t\t\t007/UMask\t\t\t002/' /etc/opendkim.conf
```

```
sudo sed -i 's/#LogWhy\t\t\tno/LogWhy\t\t\tyes/' /etc/opendkim.conf
```

```
sudo sed -i 's|#InternalHosts		192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12|ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts\nInternalHosts           refile:/etc/opendkim/TrustedHosts\nKeyTable                refile:/etc/opendkim/KeyTable\nSigningTable            refile:/etc/opendkim/SigningTable\n|' /etc/opendkim.conf
```

```
sudo sed -i 's/#Mode\t\t\tsv/Mode\t\t\tsv/' /etc/opendkim.conf
```

```
sudo sed -i 's|PidFile\t\t\t/run/opendkim/opendkim.pid|PidFile\t\t\t/var/run/opendkim/opendkim.pid\nSignatureAlgorithm      rsa-sha256|' /etc/opendkim.conf
```

```
sudo sed -i 's/UserID\t\t\topendkim/UserID\t\t\topendkim:opendkim/' /etc/opendkim.conf
```

```
sudo sed -i 's|Socket\t\t\tlocal:/run/opendkim/opendkim.sock|Socket                  inet:12301@localhost|' /etc/opendkim.conf
```

Now, we can connect the milter to Postfix

```
sudo sed -i 's|SOCKET=local:$RUNDIR/opendkim.sock|SOCKET="inet:12301@localhost"|' /etc/default/opendkim
```

And then add milter to Postfix configuration:

```
echo 'milter_protocol = 2
milter_default_action = accept
smtpd_milters = inet:localhost:12301
non_smtpd_milters = inet:localhost:12301' | sudo tee -a /etc/postfix/main.cf
```

Now it's time to create OpenDKIM folders:

```
sudo mkdir -p /etc/opendkim/keys
```

Now, let's create the files inside:

```
echo '127.0.0.1
localhost
192.168.0.1/24

*.example.com' | sudo tee -a /etc/opendkim/TrustedHosts
```

```
echo 'mail._domainkey.example.com example.com:mail:/etc/opendkim/keys/example.com/mail.private' | sudo tee -a /etc/opendkim/KeyTable
```

```
echo '*@example.com mail._domainkey.example.com' | sudo tee -a /etc/opendkim/SigningTable
```

Now, let's generate the key pair:

```
sudo mkdir /etc/opendkim/keys/example.com
cd /etc/opendkim/keys/example.com
sudo opendkim-genkey -s mail -d example.com
sudo chown opendkim:opendkim mail.private
```

Now, just print the public key file:

```
sudo cat mail.txt
```

And then, add the DNS record with the data of that file.

And finally, restart OpenDKIM and postfix

```
sudo systemctl restart opendkim
sudo systemctl restart postfix
```

And that's it, now, Postfix and your SMTP server is fully operational. You can safely change your MX record.

### Segmentation

For privacy, for filtering, and for many other reasons, you may want to segment your mailbox. And actually, if you want to use a different email address for each service, you cannot just create an alias for each, too long to do.

If you are using this mail server only for you, or for a small amount of people, you may want to use an email prefix instead of an email address. For example, you will use j.*@example.com for john doe, where the star can be anything, and it will always reach your mailbox.

> Don't even think of running that kind of configuration if you are running more than 10 mailboxes, as it will become a nightmare to make sure that there is no conflicts. An example of conflicts, let's assume alice has the email address a*@example.com and adam has the email address adam*@example.com, then there will be a conflict ad adam mail addresses may match alices ones.
>
> If you have less than 10 mailboxes, then it is very easy to manage, you can do it manually. If you want to do it at a larger scale, then it implies strong algorithms to ensure there is no conflicts, and we will not cover this part here

Right now, when a mail is sent to your mailbox, the SQL query we have configured is `SELECT maildir FROM users WHERE id='address@example.com' AND enabled=1`

What we want to do instead is `SELECT maildir FROM users WHERE 'address@example.com' REGEXP id AND enabled=1`

We could do so, but there is an issue: **The id should not be a regex**, because we use it for authentication, and we definitely don't want to have a regex for authentication. So we first need to add a column with regex to the table:

```
mysql -u mail -p
```

Then, we will add a column to the users table:

```
ALTER TABLE users ADD regex VARCHAR(128);
```

Let's now update the values in that column. First, for the `root@localhost`, quite easy as we don't want any regex

```
UPDATE users SET regex='^root@localhost$' WHERE id = 'root@localhost';
```

Now, for your user. We will assume that the address is johndoe@example.com, and that you want to match any email address in the form j.*@example.com. If you need, you can try regex to ensure it is the one you want on [ExtendsClass](https://extendsclass.com/regex-tester.html#mysql). In our case:

```
UPDATE users SET regex='^j\\..*@example\\.com$' WHERE id = 'johndoe@example.com';
```

Now, we will update the query to find a mailbox in `/etc/postfix/mysql_mailbox.cf` (You can open with nano). First, remove the following lines:

```
table=users
select_field=maildir
where_field=id
```

and also

```
additional_conditions = and enabled = 1
```

and finally, add the following line at the end:

```
query=SELECT maildir FROM users WHERE '%s' REGEXP regex AND enabled=1
```

Now, just restart postfix:

```
sudo systemctl restart postfix
```

Now, take a time to test with telnet on your computer (not on the server):

```
telnet your_ip 25
```

and then, the following commands:

```
ehlo your_server_fqdn
mail from: root@localhost
rcpt to: j.an_example_suffix@example.com
data
Here is an other test email
.
quit
```

Now that it is working, we have a configuration which may be dangerous (in a safety purpose, not on a security purpose). Our regex field in the table is nullable, and postfix relies on it to find mailboxes. This means you can add a user, forget to set the regex, and then you won't be able to receive the emails.

There is two ways to fix this:
* Relies on both the id and the regex to find a mailbox
* Make the regex field not nullable

If you prefer the first one, here is the command to do so (and it is the best to my personal point of view, as it does not force you to set a regex for each user):

```
sudo sed -i "s/'%s' REGEXP regex AND enabled=1/\(\(id='%s' AND regex IS NULL\) OR '%s' REGEXP regex\) AND enabled=1/" /etc/postfix/mysql_mailbox.cf
```

And finally, to make things cleaner, you can update root in mysql:

```
mysql -u mail -p
```

And then:

```
USE postfix;
UPDATE users SET regex=NULL WHERE id='root@localhost';
quit;
```

If you prefer the second option, then you just have to run the following command:

```
mysql -u mail -p
```

Then _(The command below will work only if regex is set for all rows of the table)_:

```
USE postfix;
ALTER TABLE users MODIFY COLUMN regex VARCHAR(128) NOT NULL;
quit;
```

And finally, that's all, you now have a fully, secure and private smtp server. Congratulations, because it is the toughest part of setting up a mail server.
