# Keep your system secure

From now on, you have installed Debian, and you have a firewall which is blocking incoming traffic. But what if a vulnerability is found in `ufw` later? This tutorial is here to show you how to keep your system up to date for security

## Problem with apt upgrade

The best way to keep your system up to date is to run the following command:

```
apt update && apt -y upgrade
```

That's the best way for being secure, and that's why it is very often the first command that is adviced to run on a fresh install.

But sometimes, you may not want to upgrade your packages. For example, if you're running PHP 7, maybe you're not ready yet to update to PHP 8. So in that context, and `apt -y update` command may make your system secure, but unstable and with bugs in your web application.

## Know the list of packages you have installed

So now, an easy question, what packages did you install on your machine ? `ufw`, and that's all right?

Actually, it is not that simple. Debian is installing a lot of packages for the basic install (for example, a shell program to let you enter the commands, a GRUB loader to let you boot on your machine, ...). Many packages are installed. And you can see a list of them by running the following command:

```
apt list --installed
```

You will see a long list of installed packages, which should be longer than your screen height. Hopefully, you don't have to remember them all. How to check if a package named `bash` is installed on your machine? You probably cannot see it, as it is above the list of results. In order to know if it is installed, you can run the following command:

```
apt list --installed | less
```

This will allow you to scroll within the list of packages. Just use the arrow down and up keys to navigate. As you can see, the list is very long, and will become longer and longer as you will install softwares. So an other way to see if packages are installed is to run the following command:

```
dpkg -l bash
```

And this will show you some information. If now you run the following command:

```
dpkg -l gcc
```

Then you can see that there it tells you that this package cannot be found. Meaning it is not installed on your server.

## So now what?

OK, it is possible to know the list of packages installed, and to know whether a package is installed or not. You can now check the [Debian Security announcements](https://www.debian.org/security/) regularly, and see if one of the latest vulnerabilities affects your system or not. Or even better, you can subscribeby email to receive each new report instantly. For each issue, they will tell you which version is fixing this issue, so you can install it. This allow you to upgrade only to the desired version.

Now, you can run the following command to update it to a specific version:

```
apt --only-upgrade install package=version
```

## Conclusion

So now, you know all you need to know to keep your system secure
