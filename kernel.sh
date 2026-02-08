#!/bin/bash

# 

# Kernel Optimization & ACPI Fixes

# Lenovo IdeaPad L340-15IRH Gaming

# 

set -e

echo “==========================================”
echo “  Kernel Parameters Optimization”
echo “==========================================”
echo “”

if [ “$EUID” -ne 0 ]; then
echo “❌ Run with sudo”
exit 1
fi

# ========================================

# פרמטרי Kernel אופטימליים

# ========================================

echo “⚙️  מגדיר kernel parameters…”

# גיבוי

cp /etc/default/grub /etc/default/grub.backup.$(date +%Y%m%d)

# הגדרות kernel

KERNEL_PARAMS=“quiet splash nvidia-drm.modeset=1 acpi_osi=! acpi_osi="Windows 2015" acpi_enforce_resources=lax i915.enable_guc=3 i915.enable_fbc=1 intel_pstate=active nowatchdog”

# עדכן GRUB

sed -i “s/GRUB_CMDLINE_LINUX_DEFAULT=".*"/GRUB_CMDLINE_LINUX_DEFAULT="$KERNEL_PARAMS"/” /etc/default/grub

# עדכן grub

update-grub

echo “✅ Kernel parameters עודכנו”

# ========================================

# Sysctl Optimizations

# ========================================

echo “”
echo “📊 מגדיר sysctl optimizations…”

cat > /etc/sysctl.d/99-ai-workstation.conf << ‘EOF’

# Network Performance

net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# VM Tuning for 8GB RAM + AI workloads

vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# File descriptors (for Docker/containers)

fs.file-max = 2097152
fs.inotify.max_user_watches = 524288

# Disable watchdog (saves CPU)

kernel.nmi_watchdog = 0
EOF

sysctl -p /etc/sysctl.d/99-ai-workstation.conf

echo “✅ Sysctl configured”

# ========================================

# I/O Scheduler Optimization

# ========================================

echo “”
echo “💾 מגדיר I/O schedulers…”

cat > /etc/udev/rules.d/60-ioschedulers.rules << ‘EOF’

# NVMe: none scheduler (best for NVMe)

ACTION==“add|change”, KERNEL==“nvme[0-9]n[0-9]”, ATTR{queue/scheduler}=“none”

# SATA HDD: BFQ scheduler (best for rotational)

ACTION==“add|change”, KERNEL==“sd[a-z]”, ATTR{queue/rotational}==“1”, ATTR{queue/scheduler}=“bfq”

# SATA SSD: mq-deadline

ACTION==“add|change”, KERNEL==“sd[a-z]”, ATTR{queue/rotational}==“0”, ATTR{queue/scheduler}=“mq-deadline”
EOF

echo “✅ I/O schedulers configured”

# ========================================

# ZRAM Configuration

# ========================================

echo “”
echo “🗜️  מגדיר ZRAM (compressed swap)…”

apt install -y zram-tools

cat > /etc/default/zramswap << ‘EOF’

# ZRAM size as percentage of RAM

PERCENT=25

# Compression algorithm

ALGO=lz4

# Priority

PRIORITY=100
EOF

systemctl enable zramswap
systemctl start zramswap || true

echo “✅ ZRAM enabled”

# ========================================

# Firmware Workarounds

# ========================================

echo “”
echo “🔧 מגדיר firmware workarounds…”

# ACPI override (אם נדרש)

mkdir -p /etc/modprobe.d

cat > /etc/modprobe.d/i915.conf << ‘EOF’

# Intel GPU optimizations

options i915 enable_guc=3 enable_fbc=1 fastboot=1
EOF

cat > /etc/modprobe.d/nvidia.conf << ‘EOF’

# NVIDIA power management

options nvidia NVreg_DynamicPowerManagement=0x02
options nvidia_drm modeset=1
EOF

echo “✅ Module options set”

# ========================================

# Systemd Optimizations

# ========================================

echo “”
echo “⚡ אופטימיזציית systemd services…”

# הפחת timeouts

mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/timeouts.conf << ‘EOF’
[Manager]
DefaultTimeoutStartSec=15s
DefaultTimeoutStopSec=15s
EOF

# NetworkManager wait-online (מהיר)

mkdir -p /etc/systemd/system/NetworkManager-wait-online.service.d
cat > /etc/systemd/system/NetworkManager-wait-online.service.d/timeout.conf << ‘EOF’
[Service]
ExecStart=
ExecStart=/usr/bin/nm-online -s -q –timeout=5
EOF

systemctl daemon-reload

echo “✅ Systemd optimized”

echo “”
echo “==========================================”
echo “✅ Kernel & System Optimization Complete!”
echo “==========================================”
echo “”
echo “🔄 Reboot נדרש:”
echo “   sudo reboot”
echo “”
echo “אחרי Reboot, בדוק:”
echo “1. cat /proc/cmdline  # Kernel parameters”
echo “2. swapon –show      # ZRAM active”
echo “3. nvidia-smi         # GPU status”
echo “”
