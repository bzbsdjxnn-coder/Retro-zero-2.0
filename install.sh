#!/bin/bash

set -e

echo "======================================"
echo " Retro Console Auto Installer"
echo "======================================"

USER_HOME=$(eval echo ~${SUDO_USER:-$USER})

# ----------------------------
# Update System
# ----------------------------
sudo apt update
sudo apt upgrade -y

# ----------------------------
# Install Required Packages
# ----------------------------
sudo apt install -y git python3-pip python3-rpi.gpio i2c-tools alsa-utils watchdog

# ----------------------------
# Install Python Libraries
# ----------------------------
pip3 install adafruit-blinka adafruit-circuitpython-seesaw python-uinput

# ----------------------------
# Install RetroPie (Basic)
# ----------------------------
if [ ! -d "$USER_HOME/RetroPie-Setup" ]; then
  git clone --depth=1 https://github.com/RetroPie/RetroPie-Setup.git $USER_HOME/RetroPie-Setup
  cd $USER_HOME/RetroPie-Setup
  sudo ./retropie_setup.sh --basic_install
  cd $USER_HOME
fi

# ----------------------------
# Enable I2C
# ----------------------------
sudo raspi-config nonint do_i2c 0

# ----------------------------
# Enable Console Autologin
# ----------------------------
sudo raspi-config nonint do_boot_behaviour B2

# ----------------------------
# Write FINAL config.txt
# ----------------------------
sudo bash -c 'cat > /boot/config.txt << EOF
enable_tvout=1
hdmi_ignore_hotplug=1
sdtv_mode=2
sdtv_aspect=3
disable_overscan=1
framebuffer_width=720
framebuffer_height=576
disable_splash=1
boot_delay=0

dtparam=audio=off
dtoverlay=hifiberry-dac
avoid_pwm_pll=1

dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=400000

arm_freq=1400
over_voltage=4
core_freq=500
gpu_freq=500
force_turbo=0
gpu_mem=192
EOF'

# ----------------------------
# Append clean boot flags
# ----------------------------
sudo sed -i 's/$/ quiet loglevel=0 logo.nologo vt.global_cursor_default=0 splash plymouth.ignore-serial-consoles/' /boot/cmdline.txt

# ----------------------------
# Enable uinput
# ----------------------------
echo "uinput" | sudo tee -a /etc/modules
sudo bash -c 'echo KERNEL==\"uinput\", MODE=\"0660\", GROUP=\"input\" > /etc/udev/rules.d/99-uinput.rules'
sudo usermod -a -G input $USER

# ----------------------------
# Copy Controller Script
# ----------------------------
sudo cp nintendo_controller.py $USER_HOME/
sudo chmod +x $USER_HOME/nintendo_controller.py

sudo bash -c "cat > /etc/systemd/system/i2cgamepad.service << EOF
[Unit]
Description=I2C Nintendo Controller
After=multi-user.target

[Service]
ExecStart=/usr/bin/python3 $USER_HOME/nintendo_controller.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl daemon-reload
sudo systemctl enable i2cgamepad.service

# ----------------------------
# Copy Shutdown Script
# ----------------------------
sudo cp shutdown-button.py /usr/local/bin/
sudo chmod +x /usr/local/bin/shutdown-button.py

sudo bash -c 'cat > /etc/systemd/system/shutdown-button.service << EOF
[Unit]
Description=Shutdown Button Service
After=multi-user.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/shutdown-button.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl enable shutdown-button.service

# ----------------------------
# Disable Unnecessary Services
# ----------------------------
sudo systemctl disable bluetooth hciuart triggerhappy

# ----------------------------
# Enable Watchdog
# ----------------------------
sudo systemctl enable watchdog

echo "======================================"
echo " Installation Complete!"
echo " Rebooting..."
echo "======================================"

sudo reboot
