#!/bin/bash

export LANG=$LANG:C
if [[ $EUID -ne 0 ]]; then
	$0 $@ 
	exit
fi

RELEASE=`cat /etc/os-release | grep -w VERSION_CODENAME | sed 's/VERSION_CODENAME=//g'`
RED="\e[1;31m"
GRN="\e[1;32m"
PNK="\e[1;35m"
WHT="\e[1;37m"
YLW="\e[1;33m"
FIN="\e[0m"

DEPENDS="alsa-utils python3 python3-setuptools libssl-dev liblzo2-2 python3-pyaudio \
	python-dbus libcurl4-openssl-dev libgcrypt20-dev libgcrypt20 libjson-c-dev \
	libavfilter-dev npm libao4 libao-common screen pulseaudio python-pexpect \
	pulseaudio-module-bluetooth bluetooth bluez bluez-tools libao-dev git gettext \
	autopoint autoconf automake pkg-config libtool device-tree-compiler libell0 gcc-9"

echo_nok(){
echo -en "${PNK}[${FIN}${GRN}OK${FIN}${PNK}]${FIN}"
}

echo_focal(){
echo -en "${PNK}[${FIN}${GRN}Ubuntu Focal${FIN}${PNK}]${FIN}"
}

echo_fail(){
echo -ne "${PNK}[${FIN}${RED}failed${FIN}${PNK}]${FIN}"
}

ierror(){
echo
echo -e "${WHT}Please check your internet connection and try again${FIN}."
}

derror(){
echo
echo -e "${WHT}The OS you are running is not supported${FIN}."
}

internet_check(){
echo -en "${WHT}Checking Internet Connection:${FIN} "
if [[ `wget -S --spider https://github.com 2>&1 | grep 'HTTP/1.1 200 OK'` ]]; then
	echo_nok
	echo ""
else
	echo_fail
	echo ""
	ierror
	exit 0
fi
}

distro_check(){
echo -en "${WHT}Checking Host Machine:${FIN} "
sleep 1s
if [[ "$RELEASE" == "focal" ]]; then
	echo_focal
	echo ""
else
	echo_fail
	echo ""
	derror
	exit 0
fi
}

# Install Pianobar
install_pianobar(){
echo "Installing Pianobar ..."
git clone https://github.com/PromyLOPh/pianobar.git
cd pianobar
make -j4 CC=/usr/bin/gcc-9
make install
cd ..
rm -fdr pianobar
}

# Install Patiobar
install_patiobar(){
echo "Installing Patiobar ..."
cd ~
git clone https://github.com/pyavitz/Patiobar.git
cd Patiobar
./install.sh
cd ~/musicbox
mkdir -p ~/bin
cp -fr bin/* ~/bin
}

# Audio setup
audio_setup(){
rm -f /etc/libao.conf
tee /etc/libao.conf <<EOF
default_driver=alsa
buffer_time=1300
quiet
EOF
cp -f audio/pulseaudio.init /etc/init.d/pulseaudio
chmod 755 /etc/init.d/pulseaudio
update-rc.d pulseaudio defaults
rm -f /usr/share/pulseaudio/alsa-mixer/profile-sets/default.conf
cp -f audio/default.conf /usr/share/pulseaudio/alsa-mixer/profile-sets/
chown root:root /usr/share/pulseaudio/alsa-mixer/profile-sets/default.conf
chown root:root /etc/libao.conf
}

# Bluetooth auto pair setup
autopair_service(){
sed -i '/#Name = BlueZ/a Enable=Source,Sink,Media' /etc/bluetooth/main.conf
sed -i 's/#Class = 0x000100/Class = 0x00041C/g' /etc/bluetooth/main.conf
sed -i 's/#DiscoverableTimeout = 0/DiscoverableTimeout = 0/g' /etc/bluetooth/main.conf
sed -i 's/#PairableTimeout = 0/PairableTimeout = 0/g' /etc/bluetooth/main.conf
sed -i 's/; resample-method = speex-float-1/resample-method = trivial/g' /etc/pulse/daemon.conf
mkdir -p /usr/local/bin
cp -f autopair/{auto-agent,autopair,bluezutils.py,BtAutoPair.py,testAutoPair.py} /usr/local/bin/
chmod +x /usr/local/bin/auto-agent
chmod +x /usr/local/bin/autopair
chown -R root:root /usr/local/bin/
tee /etc/systemd/system/autopair.service <<EOF
[Unit]
Description=Auto Pair
Requires=bluetooth.service
After=bluetooth.service
Before=rc-local.service
ConditionPathExists=/usr/local/bin/autopair

[Service]
ExecStart=/usr/local/bin/autopair > /dev/null 2>&1
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
systemctl enable autopair
systemctl start autopair
}

# Disable HDMI Audio Overlay
audio_overlay(){
if [[ `dmesg | grep -w "Raspberry\ Pi"` ]]; then
	mkdir -p /etc/initramfs/post-update.d/
	cp -f audio/98-overlay /etc/initramfs/post-update.d/
	chmod +x /etc/initramfs/post-update.d/98-overlay
	chown root:root /etc/initramfs/post-update.d/98-overlay
	/etc/initramfs/post-update.d/98-overlay
fi
}

finish(){
sleep 1s
echo -e "${WHT}Pianobar Setup"
echo "Edit the following file ~/.config/pianobar/config"
echo ""
cat ~/.config/pianobar/config
echo ""
echo export PATH="$PATH" >> ~/.bashrc
echo "and execute: start"
echo ""
sleep 1s
if [[ `dmesg | grep -w "Raspberry\ Pi"` ]]; then
	echo "To disable HDMI audio, add the following to the /boot/config.txt file"
	echo ""
	echo "dtoverlay=disable-hdmi-audio"
fi
echo -e "${FIN}"
cd ~
rm -fdr ~/musicbox
}

echo ""
internet_check
distro_check
echo ""

echo -e "${WHT}Starting install ...${FIN}"
sleep 2s
apt update
apt upgrade -y
if [[ `command -v make` ]]; then
	:;
else
	apt install -y make;
fi
apt install -y ${DEPENDS}
echo ""
install_pianobar
echo ""
install_patiobar
echo ""
echo "Running bluetooth and audio setup ..."
audio_setup > /dev/null 2>&1
autopair_service > /dev/null 2>&1
audio_overlay > /dev/null 2>&1
echo "Done."
echo ""
finish

exit 0
