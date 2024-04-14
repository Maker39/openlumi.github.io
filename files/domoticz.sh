#!/bin/sh
# Domoticz installer script by @lmahmutov
# changes for 23.05 by @Maker39


echo "start installation"
opkg update
opkg install curl git-http libmbedtls12 libustream-mbedtls shadow-usermod
opkg install liblua5.3-5.3_5.3.5-4_arm_cortex-a9_neon.ipk
opkg install lua5.3_5.3.5-4_arm_cortex-a9_neon.ipk
opkg install domoticz

usermod -a -G audio domoticz
usermod -a -G dialout domoticz

echo "Add plugin"
cd /etc/domoticz/plugins/
DIR="Domoticz-Zigate"
if [ -d "$DIR" ]; then
  # Take action if $DIR exists. #
  echo "previous installation find remove it"
  rm -r /etc/domoticz/plugins/Domoticz-Zigate
fi
git clone https://github.com/pipiche38/Domoticz-Zigate.git --depth 1
chmod +x Domoticz-Zigate/plugin.py

echo "Moving files and download domoticz config"
mv /var/lib/domoticz/domoticz.db /etc/domoticz/domoticz.db
mv /var/lib/domoticz/domoticz.db-shm /etc/domoticz/domoticz.db-shm
mv /var/lib/domoticz/domoticz.db-wal /etc/domoticz/domoticz.db-wal

sed -i -e "s:option userdata .*:option userdata '/etc/domoticz/':" /etc/config/domoticz

# TODO: consider using sed
wget https://raw.githubusercontent.com/openlumi/openlumi.github.io/master/files/domoticz_init -O /etc/init.d/domoticz
chmod 755 /etc/init.d/domoticz

chown -R domoticz:domoticz /etc/domoticz
echo "Installation complete, reboot"
# reboot
