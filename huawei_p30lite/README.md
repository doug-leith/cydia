# Huawei P30 Lite Rooting Etc

## Rooting

This is much more involved than for any of the other handsets I've looked at since Huawei no longer officially support bootloader unlocking.   The method here is based on https://forum.xda-developers.com/t/p30-lite-unlock-bootloader-paid-install-twrp-lineage-os-17-1-gsi.4235989/ but the details there now seem to have been deleted.

1. Obtain [HCU Client](https://hcu-client.com/) and [buy a 3 day license](https://www.dc-unlocker.com/buy) (€19).  You need a windows machine to run HCU client.

2. Open back of phone (its not too hard, but you need the right tools or you might damage the phone).  Connect phone by USB cable to windows machine running HCU client.  Short the phone test point and power on phone.  Phone starts to a blank screen i.e. it looks like nothing has happened.  But HCU client should detect the device if it went ok.   Note: to short the test point connect the pad shown in this [image](testpoint.png) to ground (i.e. to the metal case beside it) using e.g. a paperclip.

3. Use HCU client to unlock bootloader, and reboot phone.   This [image](PXL_20210322_074233839.jpg) shows the HCU client screen.  Select Kirin710_P1_v2 in the drop down menu, select bootload unlock and tick "reboot after repair"

4. Once phone has booted, enable developer options (tap on build number a few times) and then toggle enable the oem bootloader unlock option to on (this step disables factory reset protection FRP).  You should now have a handset with unlocked bootloader and FRP disabled.

5. Reboot to fastboot mode (power off, disconnect usb cable, press volume key down, reconnect usb cable and will power up).  Enter:

> fastboot flash recovery_ramdisk magisk_patched_riL6c.img

(you can grab the [magisk_patched_riL6c.img](magisk_patched_riL6c.img) file from this github repository).

6. Power off, remove usb cable, press volume up key+power key until Huawei logo appears.  Phone will boot off of the recovery_ramdisk partition where you flashed Magisk, and be rooted.  Its necessary to boot this way every time - if left to boot normally phone will boot off of regular boot partition and not be rooted.

7. Install [Magisk app](https://github.com/topjohnwu/Magisk/releases) and open.    Try to open an adb shell and check that su now works.

## Install Mitmproxy CA Cert

This is the same as for other handsets.

## System Process SSL Unpinning

This is much more involved for the Huawei handset since many of the system apps pin SSL certs based on a keystore embedded within the app itself.  This means that changing system level settings, such as making the mitmproxy CA cert trusted, are not enough.  Hooking of the system apps via Frida isn't viable as memory protection prevents Frida from attaching to processes (the SELinux rules also make things harder since the permissive option is disabled, but this can be worked around by creating appropriate file tags).   Modifying the system apk's to remove the pinning checks/insert mitmproxy as a valid cert doesn't work because the signature of the modified apk doesn't match what the system expects.   The solution is to use EdXposed, which modifies Zygote early in the boot process (before the memory protections kick in).  Because the first Zygote process is then cloned by all later apps, the EdXposed mods are imported into the later apps despite the memory protection measures.  

1. Open the Magisk app and install the Riru module and the EdXposed module.  Alternatively, you can copy the [riru-v25.4.2-release](riru-v25.4.2-release.zip) and [EdXposed-v0.5.2.2_4683-master-release.zip](EdXposed-v0.5.2.2_4683-master-release.zip) files from this repository, copy them to the handset using adb e.g. `adb push riru-v25.4.2-release.zip /sdcard/Download/` and `adb push EdXposed-v0.5.2.2_4683-master-release.zip /sdcard/Download/` and in the Magisk app select the install modules from storage option.  Reboot (in rooted mode) to enable them.

2. Install [JustTrustMe_DL.apk](JustTrustMe_DL.apk) from this github repository using `adb install JustTrustMe_DL.apk`.   Open the EdXposed manager app, click on the "Modules" entry on top-right menu, enable JustTrustMe module.  Reboot again (in rooted mode)  to enable this module.  That should unpin nearly all the system processes.

## Factory Reset by TWRP Wipe

1. Boot into fastboot mode.  Flash TWRP using 

> fastboot flash recovery_ramdisk twrp.img

(you can grab the [twrp.img](twrp.img) file from this github repository).  

2.  Reboot into recovery (power off, remove usb cable, press volume up key+power key until Huawei logo appears) and twrp should start.  Select Wipe and swipe the toggle for factory reset.  In addition select Advanced, tick the Internal Storage box and wipe this too (this clears the /data/media folder which is mounted as /sdcard on the phone, if it wiped then its encrypted and you'll just see garbage following the factory reset).

3. Reboot into fastboot mode.  Flash Magisk using

> fastboot flash recovery_ramdisk magisk_patched_riL6c.img

(as before you can grab the [magisk_patched_riL6c.img](magisk_patched_riL6c.img) file from this github repository).

4. Power off, remove usb cable, press volume up key+power key until Huawei logo appears.    Phone will be slower to boot as it needs to regenerate the /data partition.  When it starts it will be at the onboarding screen (like when the phone was first started from new).

5. Install/re-install the Magisk app and open.  Reboot to finish installation of Magisk.  Note: Magisk app downloads some components needed by Magisk from the web and so needs network access.  Without this Magisk is only partially installed and in particular the Riru and EdXposed modules won't install.   This need for network access can be avoided, but involves more work.  Copy the [busybox](busybox) and [util_functions.sh](util_functions.sh) files to the /data/adb/Magisk/ folder on the phone using adb (you'll need top push the files first to /data/local/tmp, then use adb shell su to copy them to /data/adb/Magisk/).  Now reboot.  It should now be possible to install Riru and EdXposed from storage.
