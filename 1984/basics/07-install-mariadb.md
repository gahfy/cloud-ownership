# Install MariaDB

Let's now install a database on our server. This can be useful for both email or web servers, so let's do it.

## Install MariaDB

As usual, it all starts with a simple apt command:

```
sudo apt -y install mariadb-server
```

Then, just secure your installation with the following command, with which you will have to set a root password.

```
sudo mysql_secure_installation
```

We suggest you to answer yes to every question.

## Tof

That's all, the MariaDB database is now installed on your server.
