#!/bin/bash

# 

# Minimal Desktop Environment Setup

# i3wm + LightDM - אופטימלי לתחנת AI

# 

set -e

echo “==========================================”
echo “  Minimal Desktop Environment Setup”
echo “  i3wm + Essential Tools Only”
echo “==========================================”
echo “”

# בדיקת root

if [ “$EUID” -ne 0 ]; then
echo “❌ Run with sudo”
exit 1
fi

REAL_USER=${SUDO_USER:-$USER}

# ========================================

# התקנת X Server + i3wm

# ========================================

echo “🖥️  מתקין X Server ו-i3wm…”

apt install -y   
xorg   
i3 i3status i3lock dmenu   
lightdm   
rofi   
picom   
feh   
alacritty   
firefox-esr   
thunar   
network-manager-gnome   
pavucontrol   
xfce4-terminal   
fonts-noto-color-emoji   
fonts-noto   
lxappearance

# ========================================

# הפעל LightDM

# ========================================

systemctl enable lightdm
systemctl set-default graphical.target

# ========================================

# תצורת i3 בסיסית

# ========================================

echo “”
echo “📝 יוצר תצורת i3 בסיסית…”

USER_HOME=$(eval echo ~$REAL_USER)
I3_CONFIG_DIR=”$USER_HOME/.config/i3”

mkdir -p “$I3_CONFIG_DIR”

cat > “$I3_CONFIG_DIR/config” << ‘EOF’

# i3 config - AI Workstation Optimized

# Mod key = Windows key

set $mod Mod4

# Font

font pango:Noto Sans 10

# Start a terminal

bindsym $mod+Return exec alacritty

# Kill focused window

bindsym $mod+Shift+q kill

# Start rofi (program launcher)

bindsym $mod+d exec rofi -show run

# Change focus

bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

# Move focused window

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# Split orientation

bindsym $mod+v split v
bindsym $mod+b split h

# Fullscreen

bindsym $mod+f fullscreen toggle

# Change container layout

bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split

# Toggle floating

bindsym $mod+Shift+space floating toggle

# Workspaces

set $ws1 “1:Terminal”
set $ws2 “2:Browser”
set $ws3 “3:AI”
set $ws4 “4:Code”
set $ws5 “5”
set $ws6 “6”
set $ws7 “7”
set $ws8 “8”
set $ws9 “9”
set $ws10 “10”

bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

# Reload/Restart i3

bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

# Exit i3

bindsym $mod+Shift+e exec “i3-msg exit”

# Lock screen

bindsym $mod+Shift+x exec i3lock -c 000000

# Bar

bar {
status_command i3status
position top
colors {
background #000000
statusline #ffffff
separator #666666
}
}

# Compositor for smooth graphics

exec_always –no-startup-id picom -b

# Network Manager applet

exec –no-startup-id nm-applet

# Volume control

bindsym XF86AudioRaiseVolume exec –no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume exec –no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute exec –no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle

# Brightness control (Fn keys)

bindsym XF86MonBrightnessUp exec –no-startup-id brightnessctl set +10%
bindsym XF86MonBrightnessDown exec –no-startup-id brightnessctl set 10%-

EOF

# תקן הרשאות

chown -R $REAL_USER:$REAL_USER “$I3_CONFIG_DIR”

echo “✅ i3wm מוכן!”
echo “”
echo “==========================================”
echo “🎨 Desktop Environment מותקן”
echo “==========================================”
echo “”
echo “Reboot למצב גרפי:”
echo “  sudo reboot”
echo “”
echo “i3wm shortcuts:”
echo “  Mod+Enter = Terminal”
echo “  Mod+D = Launcher”
echo “  Mod+Shift+Q = Close window”
echo “  Mod+Shift+E = Exit i3”
echo “”
