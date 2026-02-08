#!/bin/bash

# 

# GPU Configuration - Hybrid Compute Mode

# Intel UHD 630 (Desktop) + NVIDIA GTX 1050 (AI Compute)

# 

set -e

echo “==========================================”
echo “  GPU Hybrid Compute Configuration”
echo “==========================================”
echo “”

if [ “$EUID” -ne 0 ]; then
echo “❌ Run with sudo”
exit 1
fi

# ========================================

# NVIDIA Compute Mode (Persistence)

# ========================================

echo “🎮 מגדיר NVIDIA Compute Mode…”

# NVIDIA Persistence Daemon

systemctl enable nvidia-persistenced
systemctl start nvidia-persistenced

# הגדר persistence mode

nvidia-smi -pm 1

# הגדר power limit (אופציונלי, למנוע חום יתר)

# GTX 1050 Max-Q TDP = ~40W

nvidia-smi -pl 40

echo “✅ NVIDIA in compute mode”

# ========================================

# Prime Offload Configuration

# ========================================

echo “”
echo “🖥️  מגדיר PRIME offload…”

# יצירת תסריט הפעלה

cat > /usr/local/bin/nvidia-offload << ‘EOF’
#!/bin/bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
exec “$@”
EOF

chmod +x /usr/local/bin/nvidia-offload

echo “✅ Prime offload ready”
echo “   Usage: nvidia-offload <command>”
echo “   Example: nvidia-offload python ai_script.py”

# ========================================

# X11 Configuration

# ========================================

echo “”
echo “🖼️  מגדיר X11 למצב hybrid…”

mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/10-nvidia.conf << ‘EOF’
Section “OutputClass”
Identifier “nvidia”
MatchDriver “nvidia-drm”
Driver “nvidia”
Option “AllowEmptyInitialConfiguration”
Option “PrimaryGPU” “no”
ModulePath “/usr/lib/x86_64-linux-gnu/nvidia/xorg”
EndSection

Section “Device”
Identifier “Intel Graphics”
Driver “modesetting”
BusID “PCI:0:2:0”
Option “AccelMethod” “glamor”
Option “DRI” “3”
EndSection
EOF

# Force composition pipeline (מונע tearing)

cat > /etc/X11/xorg.conf.d/20-nvidia-options.conf << ‘EOF’
Section “Screen”
Identifier “nvidia”
Option “metamodes” “nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}”
EndSection
EOF

echo “✅ X11 configured”

# ========================================

# CUDA Setup Check

# ========================================

echo “”
echo “🔬 בודק CUDA…”

if ! command -v nvcc &> /dev/null; then
echo “⚠️  CUDA Toolkit לא מותקן”
echo “”
echo “להתקנת CUDA (אופציונלי עבור AI):”
echo “1. הורד מ: https://developer.nvidia.com/cuda-downloads”
echo “2. או: apt install nvidia-cuda-toolkit”
echo “”
else
echo “✅ CUDA מותקן: $(nvcc –version | grep release | awk ‘{print $5}’ | cut -d’,’ -f1)”
fi

# ========================================

# GPU Monitoring Script

# ========================================

echo “”
echo “📊 יוצר סקריפט ניטור GPU…”

cat > /usr/local/bin/gpu-status << ‘EOF’
#!/bin/bash
echo “==========================================”
echo “  GPU Status”
echo “==========================================”
echo “”
echo “🎮 NVIDIA GTX 1050 3GB:”
nvidia-smi –query-gpu=name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw –format=csv,noheader,nounits
echo “”
echo “🖥️  Intel UHD 630:”
cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo “N/A”
echo “”
echo “GLX Renderer:”
glxinfo | grep “OpenGL renderer” || echo “Run: sudo apt install mesa-utils”
echo “”
EOF

chmod +x /usr/local/bin/gpu-status

echo “✅ Monitoring script created”
echo “   Usage: gpu-status”

# ========================================

# Environment Variables for AI

# ========================================

echo “”
echo “🤖 מגדיר environment variables ל-AI…”

cat > /etc/profile.d/nvidia-ai.sh << ‘EOF’

# NVIDIA AI Environment

export CUDA_VISIBLE_DEVICES=0
export NVIDIA_VISIBLE_DEVICES=all
export NVIDIA_DRIVER_CAPABILITIES=compute,utility
EOF

echo “✅ Environment configured”

echo “”
echo “==========================================”
echo “✅ GPU Configuration Complete!”
echo “==========================================”
echo “”
echo “בדיקות:”
echo “1. nvidia-smi           # Status”
echo “2. gpu-status           # Full report”
echo “3. glxinfo | grep NVIDIA  # Rendering”
echo “”
echo “AI Inference:”
echo “- iGPU (Intel) מטפל בUI”
echo “- dGPU (NVIDIA) מוכן ל-CUDA workloads”
echo “”
echo “🔄 Reboot מומלץ אחרי השינויים”
echo “”
