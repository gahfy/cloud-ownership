# Install a private and secure Debian 11 on a 1984 server

This will go through the instruction of installing Debian 11 on a VPS on Debian 11.

## Prerequisites

This tutorial assumes that you already registered with 1984, and ordered a VPS which has been delivered.

Even if this tutorial may work with Tor, we encourage you to use a classic browser (Mozilla Firefox) with privacy settings on and through a VPN. You may encounter some issues with Tor in terms of performances of the emulator.

Finally, you don't need any knowledge to follow this tutorial. Each step is well detailed and illustrated so that you should easily be able to follow it even without prior knowledge.

## Setup the VPS

When you arrive on the [home page](https://www.1984hosting.com/) of 1984, click on the [Control Panel](https://1984hosting.com/signin/) link which is on the top right corner:

![](../../img/1984/basics/basics_control_panel.png)

Sign-in if you need to.

1. Then click on the [Overview](https://management.1984hosting.com/) if it is not already selected
2. Click on the `VPS Control` button of the VPS on which you want to install Debian.

![](../../img/1984/basics/basics_overview_vps_control.png)

Now, we strongly encourage you to change the reverse DNS name if you own your own domain. If you want to install a web server, or a mail server on it, search engine bots and other email servers will consider you with a slightly better score if the reverse DNS of the IP address is in the same domain.

> We advice you not to choose a service based hostname (like `mail.example.com`), but instead, having an IP based hostname (like `ip-1-2-3-4.example.com`). This because reverse DNS needs an A record matching it, and you don't want to change that. Never. Ever if you change the service you will install on it.
>
> So the best practice, for example for a mail server, would be to have an `ip-1-2-3-4` A record pointing to this IP, and having a `mail` CNAME record pointing to `ip-1-2-3-4`.

![](../../img/1984/basics/basics_edit_ptr_dns.png)

Then, click on the black block above the `Click to access the console` label in order to access the console.

![](../../img/1984/basics/basics_remote_access_console.png)

1. Click on the label with `- No image mounted -` written on it, and select Debian Bullsey 11.1.0
2. Then click on the `Mount Image` button

![](../../img/1984/basics/basics_mount_image.png)

In the alert dialog, click on the `Mount ISO and restart`. Then, everything we will do will be on the bottom of this page, where you should see the `Debian GNU/Linux installer menu`.
Just click anywhere on the screen, then you can navigate with your keyboard, using arrow keys, tab and Enter.
Just press the `Arrow Down` key on you keyboard once to select `Install`, and press the `Enter` key on your keyboard.

![](../../img/1984/basics/basics_debian_install.png)

Normally, English language should be selected. We encourage you to keep English language as we will assume it is the one selected in all the following screens, but feel free to choose an other language if you really feel not comfortable with English language. Just press the `Arrow Down` or `Arrow Up` key to select the language you prefer, and when your choice is made, press the `Enter` key to submit.

![](../../img/1984/basics/basics_debian_install_language.png)

Now, the `United States` country should be selected by default. Just press three times on the `Arrow Down` key to select `other`, then press the `Enter` key.

![](../../img/1984/basics/basics_debian_install_country_other.png)

Now, the `North America` continent should be selected. Press two times on the `Arrow Key` key to select `Europe`, then press the `Enter` key.

![](../../img/1984/basics/basics_debian_install_country_europe.png)

Now, the `Albania` country should be selected. Press twenty five times on the `Arrow Down` key to select `Iceland`, then press the `Enter` key.

![](../../img/1984/basics/basics_debian_install_country_iceland.png)

> From now on, we will assume that you know how to select an item using the `Arrow Down`, `Arrow Up` and `Enter` keys. So we will only tell you which value to select, instead of detailing how to select it.

For the locales, keep using the `United States - en_US.UTF-8` as default locale, and press the `Enter` key.

![](../../img/1984/basics/basics_debian_install_locale.png)

Then the installer will ask you about the keymap to use. Select `American english` and press `Enter` key.

![](../../img/1984/basics/basics_debian_install_keymap.png)

Then, the installer will try to configure the network using DHCP. You have nothing to do but to wait.

![](../../img/1984/basics/basics_debian_install_network_dhcp.png)

After it fails, be sure that `<Continue>` is selected before pressing `Enter`.

![](../../img/1984/basics/basics_debian_install_network_autoconfig_failed.png)

Select `Configure network manually` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_network_configuration.png)

Next screen will ask you to enter the IP address of the server. Just enter the one in the top right block, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_network_ip.png)

Next screen will ask you to enter the netmask. Just enter the one in the top right block, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_network_netmask.png)

Next screen will ask you to enter the gateway. Same as before, pick the one from the top right block, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_network_gateway.png)

Finally, next screen will ask you about the IP address of the nameservers. Write down the two address you can find on the top right block separated by a space, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_network_nameserver.png)

Then it will ask you your hostname. Just write the first part of your DNS PTR, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_network_hostname.png)

When it asks you the domain name, just write down the last part of your DNS PTR, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_network_domain_name.png)

Then, the installer will ask you to enter the password you want for the root user. Please put a **strong password**, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_root_password.png)

Then, type again the same password to ensure it was typed correctly, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_root_password_confirm.png)

Then the installer will ask you to set-up the first user, and will first ask you to put the real name of the user. We strongly encourage you to use a fake name (for privacy purposes) which looks like a real name (to avoid bugs in programs that may use it), then press `Enter`.

![](../../img/1984/basics/basics_debian_install_user_full_name.png)

Then, it will ask the username you want to use for this user. Just write down the username you want, but avoid some keywords that may be needed by some programs (`username` or `anonymous` are not good choices here). Then press `Enter`.

![](../../img/1984/basics/basics_debian_install_user_name.png)

Then the installer will ask you to enter the password for this user. Please choose a **strong password**, different from root's password, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_user_password.png)

Same as you did for root, type your user's password again to ensure it has been typed correctly, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_user_password_confirm.png)

It's now time to make the partitions of our disks. We will partition our disk the following way :

* A `/boot` partition, size 1GB, which will not be encrypted
* An encrypted volume, size the rest of the disk, which will be encrypted with aes 256, containing:
 * A `/` partition, size 5GB, ext4
 * A `swap area` partition, size matching your RAM
 * A `/data` partition, with remaining space, ext 4, on which we will store the data of the server (databases data, websites, emails, ...)

First, select `Manual` partitioning, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_manual.png)

Then, select the line matching `Virtual disk 1` and press `Enter` to make sure the disk is empty.

![](../../img/1984/basics/basics_debian_install_partition_select_disk.png)

Then press on the `Left Arrrow` key to select `<Yes>` in order to confirm the operation, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_empty_disk_confirm.png)

Then, select the line matching `pri/log - [size] GB  - FREE SPACE` and press `Enter` to create a new partition.

![](../../img/1984/basics/basics_debian_install_partition_empty_disk_select_free_space.png)

Select `Create a new partition` and then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_create_new_partition.png)

Remove the default size, type `1 GB` instead, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_boot_size.png)

Keep the type of partition `Primary` selected and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_primary.png)

For the location of the partition, keep `Beginning` selected, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_beginning.png)

Now, select the line `Mount point` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_mount_point.png)

Select the `/boot` mount point, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_mount_point_boot.png)

Then select `Done setting up the partition` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_done.png)

After this, select the `pri/log - [size] GB - FREE SPACE` line, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_after_boot_select_free_space.png)

Select `Create a new partition` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_create_new_partition.png)

Keep the default size, which is the remaining free space, and then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_encrypted_volume_size.png)

Keep the `logical` type of partition selected, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_logical.png)

Select the `Use as:` line, and then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as.png)

Select `physical volume for encryption`, and then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as_encryption.png)

Then, select the `Done setting up the partition` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_done_encryption.png)

Now, select the `COnfigure encrypted volumes` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_configure_encrypted.png)

Select `<Yes>` to write changes to the disks and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_write_changes_encrypted.png)

Then select `Create encrypted volume` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_create_encrypted.png)

Then, press on the `Arrow down` key to focus on the crypto partition, press the `Space` key to select it.

![](../../img/1984/basics/basics_debian_install_partition_select_volume_to_encrypt.png)

Then press the `Tab` key to select the `<Continue>` button, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_select_volume_to_encrypt_continue.png)

Then, select the `Finish` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_create_encrypt_finish.png)

Use the `Arrow left` key to select the `<Yes>` button in order to confirm erasing data of the partition.

![](../../img/1984/basics/basics_debian_install_partition_confirm_erase.png)

Erasing the data will take some time. All you have to do for now is to wait until it finishes. It will take few minutes, this is totally fine, please don't press `Enter` in order not to cancel it.

![](../../img/1984/basics/basics_debian_install_partition_wait_erase.png)

Once it is finished, it will ask you a passphrase to unlock the encrypted volume. Feel free to choose a **very strong one**, as it is a key you will rarely type (only on server reboot). Then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_encrypt_passphrase.png)

Then, type again the same password to ensure it was correctly typed, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_encrypt_passphrase_confirm.png)

Now, select the partition in the encrypted volume that has been created, and press `Enter`

![](../../img/1984/basics/basics_debian_install_partition_select_encrypted_partition.png)

Select the `Use as:` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_encrypted_use_as.png)

Select the `physical volume for LVM` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as_lvm.png)

Then, select `Done setting up the partition` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_done_lvm.png)

Then, select the line `Configure the Logical Volume Manager` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_configure_lvm.png)

Then press the `Arrow left` key to select `<Yes>` button to confirm write of the changes to the disk.

![](../../img/1984/basics/basics_debian_install_partition_confirm_write_changes.png)

Once you pressed `Enter` after selecting `<Yes>`, you have to configure the partitions. First, select the `create volume group` line, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_create_volume_group.png)

Now write a name for the volume group. The name does not really matters, I simply put `server_vg` where `vg` stands for virtual group. When you're done writing the name of the volume group, press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_volume_group_name.png)

Select the encrypted volume by using up and down arrow keys, and press `Space` to select. Then press `Tab` key to select `<Continue>`, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_volume_group_device.png)

Now, select the `Create a logical volume` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_lvm_create_first_volume.png)

Keep the `server_vg` group selected, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_lvm_create_volume_group.png)

Now you have to write a name for the volume. Just type `root` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_volume_name_root.png)

Now, you have to write down the size of the logical volume. Just remove the value entered, write down `5 GB` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_volume_size_root.png)

Now, select `Create logical volume` again, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_lvm_create_second_volume.png)

Once again, select the `server_vg` group and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_lvm_create_second_volume_group.png)

For the logical volume name, write down `swap` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_volume_name_swap.png)

For the size, just write down the amount of RAM you have on your server. In our case, it is `4 GB`. Then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_volume_size_swap.png)

And in order to create the last volume, select once again the `Create logical volume` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_lvm_create_third_volume.png)

Same as before, select `server_vg` for the group and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_lvm_create_third_volume_group.png)

Then, for the name, just write `data` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_volume_name_data.png)

For the size, just keep the default as it is written, which will take all the remaining free space, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_volume_size_swap.png)

Now, select the `Finish` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_lvm_finish.png)

Now, select the line matching the free space of the `root` volume, and press `Enter`. Below, we have highlighted where you can see the name of the volume.

![](../../img/1984/basics/basics_debian_install_partition_select_volume_root.png)

Now, select the `Use as` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as_root.png)

Select the `Ext4 journaling file system` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as_ext4.png)

Select the `mount point` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_mount_point_root.png)

Select the `/ -  the root filesystem` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_mount_point_root_root.png)

Then select the `Done setting up the partition` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_done_root.png)

Now select the line matching the free space of the `swap` volume and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_select_volume_swap.png)

Select the `Use as` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as_swap.png)

Select the `swap area` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as_swap_swap.png)

Then select the `Done setting up the partition` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_done_swap.png)

Last but not least, select the line matching the free space of the `data` volume, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_select_volume_data.png)

Select the `Use as` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as_data.png)

Select the `Ext4 journaling file system` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_use_as_ext4.png)

Now select the `Mount point` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_mount_point_root.png)

Then select the `enter manually` line and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_mount_point_data_manual.png)

In the nez screen, write `/data` (the `/` should already be written, so you will only have to write down `data`) and then press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_mount_point_data_data.png)

Now, just select the line `Done setting up the partition` and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_done_data.png)

Finally, select the `Finish partitioning and write changes to disk` line, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_finish.png)

On the next screen, type the `Arrow left` key to select `<Yes>` to confirm the write of the changes to the disk, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_partition_finish_confirm.png)

That's all about the partitioning. After this, the installer will start installing the base system on the server, and then will prompt you for an other media.

Just keep `<No>` selected, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_more_media.png)

Now, you have to select the country of the mirror you want to use for downloading the debian packkages. As Iceland is not an available option, we suggest you to choose `United Kingdom` which is a good choice for Iceland. Once your selection has been made press `Enter`

![](../../img/1984/basics/basics_debian_install_mirror_uk.png)

Then you have to select the mirror in that country from which you want to get the packages. The default selected one `deb.debian.org` is a good option. Just press `Enter`.

![](../../img/1984/basics/basics_debian_install_mirror_debian.png)

If you don't have any proxy for the connection, which is the case for us, just press the `Tab` key to select `<Continue>` and then press `Enter`.

![](../../img/1984/basics/basics_debian_install_mirror_proxy.png)

Then the installer will configure the package manager, install some base softwares, then will ask you if you want to participate to the package survey. We personally trust Debian, but as our goal is to increase privacy to the maximum level, we choose to not participate. If you don't have that strong privacy requirements, feel free to participate. For not participating, just press the `Enter` key.

![](../../img/1984/basics/basics_debian_install_survey.png)

Then the installer will ask you which softwares you want to install on the machine. For now, just unselect all the selected items by using `Space` key to unselect, and down and up arrow keys to navigate through items. Once all items are unselected, press the `Tab` key to focus on the `<Continue>` button, then press `Enter`.

![](../../img/1984/basics/basics_debian_install_softwares.png)

Then, the installer will install very few softwares, and will ask you whether you want to install GRUB on the primary drive or not. Keep `<Yes>` focused, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_grub.png)

Now the installer asks you on which drive you want to install GRUB. Select the only drive shown, and press `Enter`.

![](../../img/1984/basics/basics_debian_install_grub_drive.png)

Then, wait a little bit until the installer finishes the installation. Once done, you should arrive on the below screen.

![](../../img/1984/basics/basics_debian_install_finish.png)

Then, go to the top of the web page you are currently in, and click on the `Unmount image` button in the `ISO Image` section.

![](../../img/1984/basics/basics_unmount_image.png)

Then the website will warn you that it will reboot the server. Just click on `Eject ISO and restart!` to confirm your choice.

![](../../img/1984/basics/basics_unmount_image_confirm.png)

Then wait a little bit until the server restarts. You should know that it has restarted when the Qemu closes and that the website tells you that it is disconnected from Qemu.

You may need to refresh the page to see the Qemu again. It will ask you the passphrase you used to encrypt the disk. Just write it down and press `Enter`.

![](../../img/1984/basics/basics_debian_install_reboot.png)

After you wrote it, then the boot should complete, and prompt you for a login, and then a password.

![](../../img/1984/basics/basics_debian_install_after_reboot.png)

It means that Debian is well installed, in a secure and private way. Now, what you may want to do first is to [install a firewall](install_firewall.md) on your machine.
