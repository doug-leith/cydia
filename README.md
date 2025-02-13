# Inspecting Phone Network Connections

## Mitmproxy setup (for macbook):
1. If not already installed, install Homebrew, see https://brew.sh/.   Use:
  * `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
2. Install mitmproxy, see https://mitmproxy.org/.  Use:

  * `brew install mitmproxy`

3. Setup macbook as wireless AP:
  * Connect macbook to one end of a wired ethernet cable (you'll need a usb-to-ethernet adapter for this) and connect other end of ethernet cable to an internet gateway e.g. your home router.   This will be used to connect the macbook to the internet.
  * Open Settings, go to General, Sharing and click on "Internet Sharing".  
  * In the "Share your connect from" drop down box select the wired ethernet connection.  
  * In the "To computers using" box choose Wi-Fi.  
  * Click start.  You should see the Wifi icon in the top bar of the macbook change to be grayed out.  Your macbook is now acting as a WiFi access point.  Devices connecting to it will have their traffic routed over the wired ethernet cable connected to the macbook.  The name of the Wifi network will be the same as the name of the macbook, on your phone open settings, look for the available Wifi networks and connect to the macbook.

4. Setup transparent proxying using mitmproxy, see [https://docs.mitmproxy.org/stable/howto-transparent/]( https://docs.mitmproxy.org/stable/howto-transparent/) for details.  In summary:

  * Download file [https://raw.githubusercontent.com/doug-leith/cydia/main/pf.conf](pf.conf) which contains these two lines:

>`rdr on bridge100 inet proto tcp to any port {80,443} -> 127.0.0.1 port 8080`
>`block drop quick on bridge100 inet proto udp to any port 443`

  * Setup the firewall to redirect Wifi traffic to mitmdump using: `sudo pfctl -f pf.conf; sudo pfctl -e`

  * Edit file `/etc/sudoers` and add line:

>`ALL ALL=NOPASSWD: /sbin/pfctl -s state`

  * Type `mitmproxy` to start up mitmproxy for the first time, then exit.  This will create folder `~/.mitmproxy` that contains the CA cert used by mitmproxy

  * Update the permissions using `chmod a+r ~/.mitmproxy/mitmproxy-ca.pem`

  * Now type `sudo -u nobody mitmdump --mode transparent --showhost --ssl-insecure --rawtcp` to startup mitmproxy.  Traffic from the phone will now be routed to mitmproxy.  Typically you'll see errors as the phone detects the presence of mitmproxy intercepting connections.

## Mitmproxy setup (Raspberry Pi)
1. A Raspberry Pi is fine for running mitmproxy too, and much cheaper than a Macbook!  But best to use a newer Raspberry Pi 4 as I've had trouble trying to use an older Pi 3.   To set it up, first follow the [instructions](https://www.raspberrypi.org/documentation/configuration/wireless/access-point-routed.md) to configure Pi as a Wifi router.

2. Install mitmproxy by downloading the binary from https://mitmproxy.org/downloads/using (the version installed by `apt-get install mitmproxy` lags the latest release quite a bit).   Setup the firewall rules to redirect traffic to mitmproxy by running this [shell script](https://raw.githubusercontent.com/doug-leith/cydia/main/mitm_iptables.conf).

3. Run mitmproxy using e.g. `mitmdump --mode transparent --showhost --ssl-insecure --rawtcp`

## Install mitmproxy CA cert as trusted on phone
The next step is to install the CA cert of mitmproxy as a trusted cert on the phone.  
### iPhone
1. Go to Settings-WiFi and connect to laptop access point
2. Open Safari and navigate to url [http://mitm.it](http://mitm.it) (note, http not https).  Click "Get mitmproxy-ca-cert.pem" for iOS.  You'll see a message asking "This website is trying to download a configuration profile.  Do you want to allow this?", choose "Allow".
3. Go to Settings-General-Profile, you should see mitmproxy, click on it and choose "install".
4. Go to Settings-General-About and at bottom of page choose "Certificate Trust Settings".  You should see mitmproxy, click the toggle to enable full trust
5. As a test, go back to Safari and navigate to [https://leith.ie/nothingtosee.html](https://leith.ie/nothingtosee.html).  You should see connections being logged by mitmdump on the laptop as you type the URL, and then the actual connection to leith.ie/nothingtosee.html.  You may still see a few connections reporting errors, but mostly the connections should be accepted now - the connections that fail are being made by system processes, not Safari, and we need to use Cydia Substrate to make them work with mitmdump.

### Android
To install a trusted (or system) CA cert on Android requires rooting the phone.
1. Root your phone - typically this involves unlocking the bootloader (often the hardest task!).  The details of rooting are phone dependent, but you want to get to a setup where you have access to a rooted adb shell and have Magisk https://github.com/topjohnwu/Magisk installed.

2. Download the Trustusercerts Magisk module from https://github.com/lupohan44/TrustUserCertificates or use my local copy https://raw.githubusercontent.com/doug-leith/cydia/main/trustusercerts-v1.2.zip](trustusercerts-v1.2.zip).  Connect the phone to a laptop by usb cable and on the laptop use `adb shell push trustusercerts-v1.2.zip /sdcard/Download` to copy the module to the phone.  On the phone, open the Magisk app and install the trustusercerts-v1.2.zip module from storage (it is in the phone Downloads folder).  

2. On the wifi access point running mitmdump, copy the file `mitmproxy-ca-cert.pem` from folder `~/.mitmproxy/`.  This is the CA cert that mitmdump uses to sign https certs when it intercepts network connections.  Copy the mitmproxy CA cert to the phone:  
	* `adb push mitmproxy-ca-cert.pem /sdcard/Download`  
On the phone install the mitmproxy CA cert as a client CA insert.  The details change from phone to phone, but tyically open the Settings app, then the Security screen, scroll down and there is usually an "Encryptions" or "Additional Security Settings" button, click that.  Then select "Install CA cert", skip past the warnings, and select the `mitmproxy-ca-cert.pem` file from the phone Downloads folder.

3. Restart the phone.  The Trustusercerts Magisk module should promote the client CA cert that you installed to a system cert.  You can check that the mitmproxy cert has been successfully installed by looking at Settings-Security-Encryptions and credentials-Trusted Credentials on the phone - that lists the trusted CA certs and mitmproxy should be listed there if things worked ok.
	* Note: installing the mitmproxy cert as a system cert is enough to allow the traffic generated by Google Play Services etc to be decrypted by mitmproxy, but other apps may include additional pinning of SSL certs.  Those need to be treated on a case by case basis, and typically require use of a custom [Frida](https://frida.re/) script to bypass the checks.

## iPhone Cydia Substrate setup:
To bypass SSL cert checks made by iPhone system processes its necessary to jailbreak the phone.
1. Download Checkra1n from [https://checkra.in/](https://checkra.in/), install and follow instructions to jailbreak iPhone.
2. Once phone has rebooted, connect phone to a Wifi network (a normal network, not the mitmproxy one), open checkra1n app and choose option to install Cydia.  A Cydia app icon will appear on the iphone desktop.
3. Now click on the Cydia icon to open the Cydia app and:
(i) Install Cydia substrate: on tabs at bottom of screen click "search", then search for "substrate".  You should find "Substrate Safe Mode", install this and click `Respring` button.
(ii) Optional: install frida, see [https://frida.re/docs/ios/](https://frida.re/docs/ios/)
4. Install custom ssl unpinning package:
  * Open Cydia app.
  * Click on "sources" tab at bottom, then click "Edit" and "Add".  Enter [https://doug-leith.github.io/cydia/](https://doug-leith.github.io/cydia/) as new source.
  * Click on new source, the on "Tweaks" and install the "unpin" package.  Note: source code for unpin package is at [https://github.com/doug-leith/cydia](https://github.com/doug-leith/cydia)
  * We need to restart all of the system processes in order to activate the unpin package.  To do that, with phone connected by usb cable to macbook, run Checkra1n again.   
  * Once the phone has rebooted, change the settings to connect to the mitmproxy access point.  You should now see all connections being successfully decoded by mitmproxy (you may see some warning messages warning about self-signed certs (these are Apple certs) but the `--ssl-insecure` option to mitmdump allows these to pass).

Notes:
1. With phone jailbroken using Checkra1n, to access the iPhone from the command line over usb use:

  * `brew install libimobiledevice`

to install libimobiledevice package.  See [https://libimobiledevice.org/](https://libimobiledevice.org/) for details.
2. Once libimobiledevice is installed, to ssh into phone over usb use:

>`iproxy 2222 44 &`

>`ssh root@localhost -p 2222`

The password in "alpine".  To copy files off of phone use:

  * `scp -3 scp://root@localhost:2222//<file> .`

3. Once libimobiledevice is installed, to get device details use:

  * `ideviceinfo`
  
## Huawei Setup

Rooting a Huawei handset is more involved than for other handsets since Huawei no longer officially support bootloader unlocking.  Extra steps are also needed to unpin SSL cert checks made by system processes.  See [here](huawei_p30lite/README.md) for more details
