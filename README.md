### Pandora Music Player / Bluetooth Audio Receiver
**Ubuntu Focal (Arm/Arm64)**

The `install` script was tested on images built with the [rpi-img-builder](https://github.com/pyavitz/rpi-img-builder). I can't say with any certainty, it will work with an official Ubuntu Focal release.

**Boards:**
* Raspberry Pi 2/3/4/A/B/+
* [Raspberry Pi Hardware](https://www.raspberrypi.org/documentation/hardware/raspberrypi)

*Target Device:* `Raspberry Pi 3A+`

---

**Applications:**
* Pianobar ... [Console client](https://github.com/PromyLOPh/pianobar)
* Patiobar ... [Web interface](https://github.com/pyavitz/Patiobar)
* Bluez

**Recommends:**
* Dongle ... Bluetooth (low energy)
* SSH Button ... [Android App](https://play.google.com/store/apps/details?id=com.pd7l.sshbutton&hl=en_US)
* Amp Modules ... [PAM8403](https://www.amazon.com/PAM8403-Channel-Digital-Amplifier-Potentionmeter/dp/B01MYTZGYM) [PAM8406](https://www.ebay.com/itm/Amplifier-Board-Class-D-Audio-5W-5W-Module-Dual-Channel-PAM8406-DIY-Stereo-Mini/313153265326?_trkparms=aid%3D777001%26algo%3DDISCO.FEED%26ao%3D1%26asc%3D225074%26meid%3D56ccad57a0b3470196bc7664442aad56%26pid%3D100651%26rk%3D1%26rkt%3D1%26mehot%3Dnone%26itm%3D313153265326%26pmt%3D1%26noa%3D1%26pg%3D2380057%26algv%3DPersonalizedTopicsRefactor%26brand%3D&_trksid=p2380057.c100651.m4497&_trkparms=pageci%3A7e3b7455-d363-11ea-ac52-ae0bcbae8747%7Cparentrq%3Aa65578871730a45e5bf83bf0ffd9ca44%7Ciid%3A1)

### Headless Usage:
```sh
Create keygen: ssh-keygen
Copy to target device: ssh-copy-id user@ipaddress
```
```sh
nano ~/.ssh/config
Host musicbox
        User username
        HostName ipaddress
        Port 22
        ForwardX11 no
```
```sh
nano ~/.config/musicbox
start(){
ssh musicbox '~/bin/start'
}
stop(){
ssh musicbox '~/bin/stop'
}
play(){    # play/pause
ssh musicbox '~/bin/play'
}
song(){
ssh musicbox '~/bin/song'
}
next(){
ssh musicbox '~/bin/next'
}
volup(){
ssh musicbox '~/bin/volup'
}
voldn(){
ssh musicbox '~/bin/voldn'
}
mute(){
ssh musicbox '~/bin/mute'
}
unmute(){
ssh musicbox '~/bin/unmute'
}
```
```sh
nano ~/.bashrc
source  ~/.config/musicbox
```
Add a radio station: `sudo apt install -y mplayer`
```sh
nano ~/.config/musicbox
isla(){		# isla negra
ssh musicbox 'mplayer -nocache -prefer-ipv4 http://66.228.60.216:8002/stream'
}
```
You can also map a bluetooth remote or controller and use the `~/bin/scripts` to control the Pi / Pianobar.
The following [link](https://raspberry-valley.azurewebsites.net/Map-Bluetooth-Controller-using-Python/) explains the basics.

---

In the case of using a `USB Sound Card Adaptor` this is my following setup.
```sh
cat /etc/asound.conf
pcm.!default {
        type hw
        card 1
}

ctl.!default {
        type hw           
        card 1
}
```
Disable the onboard audio
```sh
nano /boot/config.txt
# enable audio (loads snd_bcm2835)
#dtparam=audio=on
```
```sh
nano /etc/modules
#snd_bcm2835
```
