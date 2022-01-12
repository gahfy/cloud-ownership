# Install Dovecot

OK, that's great, you now have an SMTP server which is fully fonctional, let's now focus on adding an IMAP server.

```
sudo apt -y install dovecot-core dovecot-imapd dovecot-lmtpd dovecot-mysql
```

Then, add the protocols you want for dovecot:

```
sudo sed -i 's|\(!include_try /usr/share/dovecot/protocols.d/\*.protocol\)|\1\nprotocols = imap lmtp|' /etc/dovecot/dovecot.conf
```

Then disable plaintext authentication:

```
sudo sed -i 's/#\(disable_plaintext_auth = yes\)/\1/' /etc/dovecot/conf.d/10-auth.conf
```

And put the authentication mechanisms:

```
sudo sed -i 's/\(auth_mechanisms = plain\)/\1 login/' /etc/dovecot/conf.d/10-auth.conf
```

Then, remove the system authentication:

```
sudo sed -i 's/\(!include auth-system.conf.ext\)/#\1/' /etc/dovecot/conf.d/10-auth.conf
```

And add the mysql configuration instead:

```
sudo sed -i 's/#\(!include auth-sql.conf.ext\)/\1/' /etc/dovecot/conf.d/10-auth.conf
```

Now, set the mail directory for the users:

```
sudo sed -i 's|mail_location = mbox:~/mail:INBOX=/var/mail/%u|mail_location = maildir:/data/mail/virtual/%u|' /etc/dovecot/conf.d/10-mail.conf
```

Then add the inbox format:

```
sudo sed -i '0,/#separator =/{s//separator = ./}' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i '0,/#prefix =/{s//prefix = INBOX./}' /etc/dovecot/conf.d/10-mail.conf
```

Then add the user and the group:

```
sudo sed -i 's/#\(mail_uid =\)/\1 5000/' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i 's/#\(mail_gid =\)/\1 5000/' /etc/dovecot/conf.d/10-mail.conf
sudo sed -i 's/\(mail_privileged_group = \)mail/\1virtual/' /etc/dovecot/conf.d/10-mail.conf
```

Now, we want to remove IMAP port. We want to use IMAPS, and IMAPS only:

```
sudo sed -i 's/inet_listener imap \{\n    #port = 143\n  \}/#inet_listener imap \{\n    #port = 143\n  #\}/' /etc/dovecot/conf.d/10-master.conf
sudo sed -i '0,/}/{s//#}/}' /etc/dovecot/conf.d/10-master.conf
```

Now, it's time to configure SSL. Same as for Postfix, we want to have an SSL certificate which will be issued by Let's Encrypt:

```
sudo certbot certonly --standalone
```

Then, choose the domain name you want for IMAP. I personnally choosed `imap.example.com` _(Don't forget to add a CNAME record pointing to that domain)_

Then, you can set the SSL configuration (_Remember to replace imap.example.com by your own domain_):

```
sudo sed -i 's|ssl_cert = </etc/dovecot/private/dovecot.pem|ssl_cert = </etc/letsencrypt/live/imap.example.com/cert.pem|' /etc/dovecot/conf.d/10-ssl.conf
sudo sed -i 's|ssl_key = </etc/dovecot/private/dovecot.key|ssl_key = </etc/letsencrypt/live/imap.example.com/privkey.pem|' /etc/dovecot/conf.d/10-ssl.conf
```

Now, let's increase the number of allowed connections from a same IP to 100 (some clients may make many requests at the same time):

```
sudo sed -i 's/#\(mail_max_userip_connections = 10\)/\10/' /etc/dovecot/conf.d/20-imap.conf
```

Now, dovecot by default get user information from a separate request than the one requesting the password. Let's remove this default behavior:

```
sudo sed -i ':a;N;$!ba;s/driver = sql/driver = prefetch/2' /etc/dovecot/conf.d/auth-sql.conf.ext
sudo sed -i ':a;N;$!ba;s|\(args = /etc/dovecot/dovecot-sql.conf.ext\)|#\1|2' /etc/dovecot/conf.d/auth-sql.conf.ext
```

Finally, let's implement the SQL configuration:

```
echo '#For database driver, we want mysql:
driver = mysql

#The connect string will point to the postfix database on the local machine,
#with the user and password you defined when you set it up according to Flurdy.
connect = host=127.0.0.1 dbname=postfix user=mail password=mailPASSWORD

#We'll be using the encrypted password from the mysql database:
default_pass_scheme = CRYPT

#Set the password query to point to the users table:
password_query = SELECT id AS user, crypt AS password, CONCAT(home,'/',maildir) AS userdb_home, \
                        uid AS userdb_uid, gid AS userdb_gid, CONCAT(home,'/',maildir) AS userdb_mail FROM users WHERE id='%u' | tee -a /etc/dovecot/dovecot-sql.conf.ext
```

And that's it, now restart dovecot:

```
sudo systemctl restart dovecot
```

By default, IMAP will listen to the port 143 (IMAP without SSL). Actually we don't care as we will not open this port. Now time to open IMAPS port:

Replace 1.2.3.4 by the actual IP you will use to connect through IMAP:

```
sudo ufw allow from 1.2.3.4 to any port 993
```
