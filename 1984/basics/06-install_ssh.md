# Install SSH

Running commands through Qemu can be quite boring. That's why we will see in this tutorial how to install SSH.

## Install package

Run the following command in the Qemu:

```
sudo apt -y install openssh-server
```

## Configure firewall

For now, we strongly encourage you to use a VPN or a static IP address, in order not to let the SSH port open to the world. Run the following command to open the SSH port to a specific IP address:

```
sudo ufw allow from 1.2.3.4 to any port 22 proto tcp
```

If you don't have a VPN, and are not sure that your IP is static, just get your current public IP address, and assuming that it is `1.2.3.4`, the following command should let you use SSH without any issue, at least for a good amount of time:

```
sudo ufw allow from 1.2.3.0/24 to any port 22 proto tcp
```
_See how the last number of the IP address has been replaced by a zero_

## Connect through SSH

Now, all you have to do is to run on your personal machine the following command:

```
ssh username@ip_address_of_server
```

Then it will prompt for your password, and let you in.

## Configure SSH

See how it is easy to connect with your password through SSH. The problem is that it only requires your password to get connected. And your password is something you will type a lot, every time you connect, every time you run a sudo command... so we want to enable 2FA.

### What is 2FA

2FA, standing for two factors authentication, is an authentication method that uses two factors. To make it more secure, we choose one of the factor to be something you know (like your password) and the other something you own (like your phone, a FIDO key, or anything else).

A good way to provide 2FA when dealing with SSH connections is to use an SSH key. The private key will be the factor you own, and the passphrase associated to that key will be the factor you know.

### Generate SSH key

In order to generate an SSH key, you need to execute the following command on your machine (the machine you will use to connect to the server, not the server):

```
ssh-keygen -C "your_email@example.com"
```

When you run through the process, it is very important that you set a passphrase. Remember about 2FA, something you own (the computer which has the certificate) and something you know (the password).

### Add SSH key to the server

On the machine on which you generated the certificate, run the following command:

```
scp ~/.ssh/id_rsa.pub serverusername@serverip:/home/serverusername
```

Now, connect to the machine through SSH, and run the following commands:

```
mkdir ~/.ssh
mv ~/id_rsa.pub ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Now, we need to allow authentication using public keys:

```
sudo sed -i 's/#\(PubkeyAuthentication yes\)/\1/' /etc/ssh/sshd_config
```

And to disable password authentication:

```
sudo sed -i 's/#\(PasswordAuthentication\) yes/\1 no/'  /etc/ssh/sshd_config
```

Now, all you need to do is to restart ssh deamon:

```
sudo systemctl restart sshd
```

Now, if you exit your current SSH session and connect again, it will ask the passphrase of your key, and that's all, you're in.

### Remove sudo password

When you run sudo command, you will have to type your user's password. You can remove it with the following command:

```
sudo sed -i 's/username   ALL=(ALL) ALL/username     ALL=(ALL) NOPASSWD:ALL/' /etc/sudoers
```

Then, you will no longer need the user's password when running the sudo command.

## Optional recommended configuration

There is still a door open to access your server: the Qemu.

You can close this door with the following command:

```
sudo passwd -l username
```

Something very important to notice here is how dangerous this command is in terms of convenience. If you loose your SSH key (for example by formatting your computer) and/or if you cannot access anymore to the IP address that is allowed to connect through SSH port, you have no ways at all to access your machine. You will have to reinstall it from scratch.

For security purposes, it's a very good thing, but for convenience, it is maybe not so desirable.

If you run the command before reading this warning, you can cancel it by running the following command.

```
sudo passwd -u username
```
