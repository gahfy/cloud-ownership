# Installing sudo

Using the `root` user every time is not good. It force you to type the root password many times, and give no history about what happend with who. That's why it is good to install the `sudo` package.

## Installing the package

Installing the package is quite easy:

```
apt -y install sudo
```

Now, let's add the gahfy user as sudo. Just run the command:

## Configuring sudo

```
sudo visudo
```

then add this line to the end of the file (use the arrow keys to navigate):

```
username  ALL=(ALL) ALL
```
_Replace username by the actual username of the user you created at install time._

Once done, just do `Ctrl+O` to save, and `Ctrl+X` to quit the editor.

## Using sudo

Now, you can exit the `root` session with the following command

```
exit
```

And log in as the user you created during install.

## Remove root login

Once logged as the user, try to run the following command:

```
sudo visudo
```

It will ask you your user password again, and you should arrive after that to the same editor as before.

Just quit this editor by pressing `Ctrl+X`. This was just to be sure that everything worked.

Now that you can run commands with root privilege, you have no reason to connect as `root` to the machine. So just run the following command:

```
sudo passwd -l root
```

Once done, you can try to login as root with:

```
su root
```

It should fail. There is no more way to log in as root, so it is one more door which is closed.
