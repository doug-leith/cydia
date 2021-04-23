# Huawei P30 Rooting Etc

## Rooting

This is much more involved than for any of the other handsets I've looked at since Huawei no longer officially support bootloader unlocking.   The method here is based on [https://forum.xda-developers.com/t/p30-lite-unlock-bootloader-paid-install-twrp-lineage-os-17-1-gsi.4235989/].

1. Obtain [https://hcu-client.com/](HCU Client) and [https://www.dc-unlocker.com/buy](buy a 3 day license) (€19).  You need a windows machine to run HCU client.

2. Open back of phone (its not too hard, but you need the right tools or you might damage the phone).  Connect phone by USB cable to windows machine running HCU client.  Short the phone test point and power on phone.  Phone starts to a blank screen i.e. it looks like nothing has happened.  But HCU client should detect the device if it went ok.

3. Use HCU client to unlock bootloader, and reboot phone.   This [PXL_20210322_074233839.jpg](image) shows the HCU client screen.  Select Kirin710_P1_v2 in the drop down menu, select bootload unlock and tick "reboot after repair"

4. Once phone has booted, enable developer options (tap on build number a few times) and then toggle enable the oem bootloader unlock option to on (this step disables factory reset protection FRP).  You should now have a handset with unlocked bootloader and FRP disabled.

5. Reboot to fastboot mode (power off, disconnect usb cable, press volume key down, reconnect usb cable and will power up).  Enter:

>fastboot flash recovery_ramdisk magisk_patched_riL6c.img

(you can grab the magisk_patched_riL6c.img file from this github repository).

6. Power off, remove usb cable, press volume up key+power key until Huawei logo appears.  Phone will boot off of the recovery_ramdisk partition where you flashed Magisk, and be rooted.  Its necessary to boot this way every time - if left to boot normally phone will boot off of regular boot partition and not be rooted.

7. Install [https://github.com/topjohnwu/Magisk/releases](Magisk app) and open.    Try to open an adb shell and check that su now works.

## Install Mitmproxy CA Cert

This is the same as for other handsets.

## System Process SSL Unpinning

This is much more involved for the Huawei handset since many of the system apps pin SSL certs based on a keystore embedded within the app itself.  This means that changing system level settings, such as making the mitmproxy CA cert trusted, are not enough.  Hooking of the system apps via Frida isn't viable as memory protection prevents Frida from attaching to processes (the SELinux rules also make things harder since the permissive option is disabled, but this can be worked around by creating appropriate file tags).   Modifying the system apk's to remove the pinning checks/insert mitmproxy as a valid cert doesn't work because the signature of the modified apk doesn't match what the system expects.   The solution is to use EdXposed, which modifies Zygote early in the boot process (before the memory protections kick in).  Because the first Zygote process is then cloned by all later apps, the EdXposed mods are imported into the later apps despite the memory protection measures.  

1. Open the Magisk app and install the Riru module and the EdXposed module.  Reboot (in rooted mode) to enable them.

2. Install JustTrustMe_DL.apk from this github repository.   Open the EdXposed manager app, click on the "Modules" entry on top-right menu, enable JustTrustMe module.  Reboot again to enable this module.  That should unpin nearly all the system processes.



