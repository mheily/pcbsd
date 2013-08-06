#!/bin/sh
# Script which does some first time init

case $1 in
 desktop|server) ;;
              *) echo "Error: Please specify 'desktop' or 'server'"
                 exit 1
                 ;;
esac

################################################
# Do generic init
################################################

if [ ! -d "/usr/home" ] ; then
   mkdir /usr/home
fi

# Setup /home link
if [ ! -e "/home" ] ; then
  ln -s /usr/home /home
fi

# Init the firewall
sh /usr/local/share/pcbsd/scripts/reset-firewall

# Update XDG menus
/usr/local/bin/pc-xdgutil updatemenu

# Update ports overlay files
/usr/local/bin/pc-extractoverlay ports

# Add our notice to top of loader.conf
mv /boot/loader.conf /boot/loader.conf.tmp
cat <<EOF >/boot/loader.conf
# * IMPORTANT NOTICE *
# Run 'grub-mkconfig -o /boot/grub/grub.cfg' after making changes to this file
###############################################################################
EOF
cat /boot/loader.conf.tmp >> /boot/loader.conf
rm /boot/loader.conf.tmp

################################################
# Do desktop specific init
################################################
if [ "$1" = "desktop" ] ;then
  # Allow shutdown / reboot from hal
  polkit-action --set-defaults-any org.freedesktop.hal.power-management.shutdown yes
  polkit-action --set-defaults-any org.freedesktop.hal.power-management.reboot yes

  # Init the flash plugin for all users
  cd /home
  for i in `ls -d * 2>/dev/null`
  do
    su ${i} -c "flashpluginctl off"
    su ${i} -c "flashpluginctl on"
  done

  # Enable the system updater tray
  pbreg set /PC-BSD/SystemUpdater/runAtStartup true

  # Set running desktop
  pbreg set /PC-BSD/SysType PCBSD
  touch /etc/defaults/pcbsd

  # Init the desktop
  /usr/local/bin/pc-extractoverlay desktop --sysinit

  # Check if we need to load i915kms
  kldstat | grep -q "i915kms"
  if [ $? -eq 0 ] ; then
     echo "iicbb_load=\"YES\"" >> /boot/loader.conf
     echo "iicbus_load=\"YES\"" >> /boot/loader.conf
     echo "iic_load=\"YES\"" >> /boot/loader.conf
     echo "drm2_load=\"YES\"" >> /boot/loader.conf
     echo "i915kms_load=\"YES\"" >> /boot/loader.conf
  fi

  # Need to save a language?
  if [ -n "$2" ] ; then
     echo "$2" > /etc/pcbsd-lang
  fi
  exit $?
fi

################################################
# Do server specific init
################################################
if [ "$1" = "server" ] ; then
  # Set running a server
  pbreg set /PC-BSD/SysType TRUEOS
  touch /etc/defaults/trueos

  # Init the server
  /usr/local/bin/pc-extractoverlay server --sysinit
  exit $?
fi
