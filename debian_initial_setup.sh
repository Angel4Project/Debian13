#!/bin/bash

# 

# Debian 13 Post-Installation Setup

# Lenovo IdeaPad L340-15IRH Gaming - AI Workstation

# 

# תסריט הגדרה ראשונית אחרי התקנת Debian

# 

set -e  # עצור אם יש שגיאה

echo “==========================================”
echo “  Debian 13 AI Workstation Setup”
echo “  Lenovo IdeaPad L340-15IRH Gaming”
echo “==========================================”
echo “”

# בדיקה שרץ כ-root

if [ “$EUID” -ne 0 ]; then
echo “❌ יש להריץ עם sudo:”
echo “   sudo bash $0”
exit 1
fi

# שמירת שם המשתמש האמיתי

REAL_USER=${SUDO_USER:-$USER}
echo “✅ משתמש: $REAL_USER”
echo “”

# ========================================

# שלב 1: עדכון מערכת

# ========================================

echo “📦 [1/8] מעדכן את המערכת…”
apt update
apt upgrade -y
apt dist-upgrade -y

# ========================================

# שלב 2: התקנת כלים בסיסיים

# ========================================

echo “”
echo “🔧 [2/8] מתקין כלים בסיסיים…”
apt install -y   
curl wget git vim nano   
build-essential dkms linux-headers-$(uname -r)   
software-properties-common apt-transport-https   
ca-certificates gnupg lsb-release   
htop btop neofetch   
net-tools wireless-tools   
ufw fail2ban   
unzip zip p7zip-full   
tmux screen   
python3 python3-pip python3-venv   
nodejs npm

# ========================================

# שלב 3: הוספת Non-Free Repositories

# ========================================

echo “”
echo “📚 [3/8] מוסיף repositories ל-firmware ודרייברים…”

# ודא שיש non-free ו-contrib

if ! grep -q “non-free” /etc/apt/sources.list; then
echo “deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware” > /etc/apt/sources.list
echo “deb http://deb.debian.org/debian/ trixie-updates main contrib non-free non-free-firmware” >> /etc/apt/sources.list
echo “deb http://deb.debian.org/debian-security trixie-security main contrib non-free non-free-firmware” >> /etc/apt/sources.list
apt update
fi

# ========================================

# שלב 4: Firmware ודרייברים

# ========================================

echo “”
echo “💾 [4/8] מתקין firmware…”
apt install -y   
firmware-linux   
firmware-linux-nonfree   
firmware-misc-nonfree   
firmware-iwlwifi   
intel-microcode

# טען מחדש firmware אלחוטי

modprobe -r iwlwifi 2>/dev/null || true
modprobe iwlwifi

# ========================================

# שלב 5: NVIDIA Drivers

# ========================================

echo “”
echo “🎮 [5/8] מכין להתקנת NVIDIA drivers…”

# התקן NVIDIA driver מ-Debian repositories

apt install -y nvidia-driver nvidia-settings nvidia-smi

# הוסף nvidia-drm.modeset=1 ל-kernel parameters

if ! grep -q “nvidia-drm.modeset=1” /etc/default/grub; then
sed -i ‘s/GRUB_CMDLINE_LINUX_DEFAULT=”/GRUB_CMDLINE_LINUX_DEFAULT=“nvidia-drm.modeset=1 /’ /etc/default/grub
update-grub
fi

echo “⚠️  NVIDIA driver יפעל אחרי reboot”

# ========================================

# שלב 6: Thermal Management

# ========================================

echo “”
echo “🌡️  [6/8] מגדיר ניהול תרמי…”

# התקן thermald

apt install -y thermald
systemctl enable thermald
systemctl start thermald

# הורד ו-התקן throttled עבור Lenovo

if [ ! -f /usr/local/bin/throttled ]; then
echo “📥 מוריד lenovo-throttling-fix…”
cd /tmp
git clone https://github.com/erpalma/throttled.git
cd throttled

```
# התקן
./install.sh

echo "✅ throttled מותקן - יפעיל אחרי reboot"
```

fi

# ========================================

# שלב 7: Docker

# ========================================

echo “”
echo “🐳 [7/8] מתקין Docker…”

# הוסף Docker repository

mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg –dearmor -o /etc/apt/keyrings/docker.gpg
echo   
“deb [arch=$(dpkg –print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian   
$(lsb_release -cs) stable” | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# הוסף משתמש ל-docker group

usermod -aG docker $REAL_USER

# אופטימיזציה: עיכוב start של Docker

mkdir -p /etc/systemd/system/docker.service.d
cat > /etc/systemd/system/docker.service.d/override.conf << ‘EOF’
[Unit]
After=network-online.target
Wants=network-online.target

[Service]

# הפחת timeout

TimeoutStartSec=30s
EOF

systemctl daemon-reload
systemctl enable docker

# ========================================

# שלב 8: Firewall בסיסי

# ========================================

echo “”
echo “🔒 [8/8] מגדיר Firewall…”

# UFW - פשוט וטוב

ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw –force enable

echo “”
echo “==========================================”
echo “✅ ההתקנה הבסיסית הושלמה!”
echo “==========================================”
echo “”
echo “🔄 נדרש Reboot עכשיו:”
echo “   sudo reboot”
echo “”
echo “אחרי Reboot:”
echo “1. בדוק NVIDIA: nvidia-smi”
echo “2. בדוק Docker: docker run hello-world”
echo “3. המשך להגדרת סביבה גרפית”
echo “”
