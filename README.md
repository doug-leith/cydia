## Inspecting Phone Network Connections

#Mitmproxy setup (for macbook):
1. If not already installed, install Homebrew, see https://brew.sh/.   Use:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
2. Install mitmproxy, see https://mitmproxy.org/.  Use:
brew install mitmproxy
3. Setup macbook as wireless AP:
(i) Connect macbook to one end of a wired ethernet cable (you'll need a usb-to-ethernet adapter for this) and connect other end of ethernet cable to an internet gateway e.g. your home router.   This will be used to connect the macbook to the internet.
(ii) Open Settings, go to Sharing and click on "Internet Sharing".  In the "Share your connect from" drop down box select the wired ethernet connection.  In the "To computers using" box choose Wi-Fi.  Click start.  You should see the Wifi icon in the top bar of the macbook change to be grayed out.  Your macbook is now acting as a WiFi access point.  Devices connecting to it will have their traffic routed over the wired ethernet cable connected to the macbook.  The name of the Wifi network will be the same as the name of the macbook, on your phone open settings, look for the available Wifi networks and connect to the macbook.
4. Follow instructions at https://docs.mitmproxy.org/stable/howto-transparent/ to setup transparent proxying.  In summary:
(i) create file pf.conf with these two lines:
rdr on bridge100 inet proto tcp to any port {80,443} -> 127.0.0.1 port 8080
block drop quick on bridge100 inet proto udp to any port 443
(ii) sudo pfctl -f pf.conf; sudo pfctl -e
(iii) edit file /etc/sudoers and add line:
ALL ALL=NOPASSWD: /sbin/pfctl -s state
(iv) Type "mitmproxy" to start up mitmproxy for the first time, then exit.  This will create folder ~/.mitmproxy that contains the CA cert used by mitmproxy
(v) chmod a+r ~/.mitmproxy/mitmproxy-ca.pem.
(vi) Nowe type:
sudo -u nobody mitmdump --mode transparent --showhost --ssl-insecure
Traffic from the phone will now be routed to mitmproxy.  Typically you'll see errors as the phone detects the presence of mitmproxy intercepting connections.

#Install mitmproxy CA cert as trusted on phone
The next step is to install the CA cert of mitmproxy as a trusted cert on the phone.  To do this on an iphone:
(a) Go to Settings-WiFi and connect to laptop access point
(b) Open Safari and navigate to url http://mitm.it (note, http not https).  Click "Get mitmproxy-ca-cert.pem" for iOS.  You'll see a message asking "This website is trying to download a configuration profile.  Do you want to allow this?", choose "Allow".
(c) Go to Settings-General-Profile, you should see mitmproxy, click on it and choose "install".
(d) Go to Settings-General-About and at bottom of page choose "Certificate Trust Settings".  You should see mitmproxy, click the toggle to enable full trust
(e) As a test, go back to Safari and navigate to https://leith.ie/nothingtosee.html.  You should see connections being logged by mitmdump on the laptop as you type the URL, and then the actual connection to leith.ie/nothingtosee.html.  You may still see a few connections reporting errors, but mostly the connections should be accepted now - the connections that fail are being made by system processes, not Safari, and we need to use Cydia Substrate to make them work with mitmdump.

#iPhone Cydia Substrate setup:
1. Download Checkra1n from https://checkra.in/, install and follow instructions to jailbreak iphone.
2. Once phone has rebooted, connect phone to a Wifi network (a normal network, not the mitmproxy one), open checkra1n app and choose option to install Cydia.  A Cydia app icon will appear on the iphone desktop.
3. Now click on the Cydia icon to open the Cydia app and:
(i) Install Cydia substrate: on tabs at bottom of screen click "search", then search for "substrate".  You should find "Substrate Safe Mode", install this and click Respring button.
(ii) Optional: install frida, see https://frida.re/docs/ios/
4. Install ssl unpinning script:
(i) Open Cydia app.
(ii) Click on "sources" tab at bottom, then click "Edit" and "Add".  Enter "https://doug-leith.github.io/cydia/" as new source.
(iii)  Click on new source, the on "Tweaks" and install the "unpin" package.  Note: source code for unpin package is at https://github.com/doug-leith/cydia
(iv) We need to restart all of the system processes in order to activate the unpin package.  To do that, with phone connected by usb cable to macbook, run Checkra1n again.  This will reboot the phone while keeping it jailbroken.
(v) Change the phone to connect to the mitmproxy access point.  You should now see all connections being successfully decoded by mitmproxy (you may see some warning messages warning about self-signed certs (these are Apple certs) but the --ssl-insecure option to mitmdump allows these to pass).

Notes:
1. With phone jailbroken using Checkra1n, to access iphone from command line over usb use:
brew install libimobiledevice
to install libimobiledevice package.  See https://libimobiledevice.org/ for details
2. Once libimobiledevice is installed, to ssh into phone over usb use:
iproxy 2222 44 &
ssh root@localhost -p 2222
The password in "alpine".  To copy files off of phone use:
scp -3 scp://root@localhost:2222//<file> .
3. Once libimobiledevice is installed, to get device details use:
ideviceinfo
