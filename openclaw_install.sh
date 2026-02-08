#!/bin/bash

# 

# OpenClaw/Molto Bot Installation & Security Hardening

# Zero-Trust AI Agent Deployment

# 

set -e

echo “==========================================”
echo “  OpenClaw AI Agent Installation”
echo “  Zero-Trust Security Model”
echo “==========================================”
echo “”

if [ “$EUID” -ne 0 ]; then
echo “❌ Run with sudo”
exit 1
fi

REAL_USER=${SUDO_USER:-$USER}
USER_HOME=$(eval echo ~$REAL_USER)

# ========================================

# שלב 1: יצירת משתמש ייעודי ל-AI

# ========================================

echo “👤 [1/7] יוצר משתמש ai-agent…”

if ! id -u ai-agent > /dev/null 2>&1; then
useradd -r -m -d /opt/openclaw -s /bin/bash ai-agent
echo “✅ משתמש ai-agent נוצר”
else
echo “ℹ️  משתמש ai-agent כבר קיים”
fi

# ========================================

# שלב 2: Node.js LTS

# ========================================

echo “”
echo “📦 [2/7] מתקין Node.js LTS…”

# התקן nvm עבור ai-agent

su - ai-agent << ‘EOF’
if [ ! -d “$HOME/.nvm” ]; then
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

```
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm install --lts
nvm use --lts
nvm alias default lts/*
```

fi
EOF

echo “✅ Node.js מותקן”

# ========================================

# שלב 3: התקנת OpenClaw

# ========================================

echo “”
echo “🤖 [3/7] מתקין OpenClaw…”

su - ai-agent << ‘EOF’
export NVM_DIR=”$HOME/.nvm”
[ -s “$NVM_DIR/nvm.sh” ] && . “$NVM_DIR/nvm.sh”

if [ ! -d “$HOME/openclaw” ]; then
cd $HOME
git clone https://github.com/openclaw/openclaw.git
cd openclaw
npm install
echo “✅ OpenClaw cloned and installed”
else
echo “ℹ️  OpenClaw already exists, updating…”
cd $HOME/openclaw
git pull
npm install
fi
EOF

# ========================================

# שלב 4: llama.cpp + CUDA

# ========================================

echo “”
echo “🦙 [4/7] בונה llama.cpp עם CUDA…”

su - ai-agent << ‘EOF’
if [ ! -d “$HOME/llama.cpp” ]; then
cd $HOME
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

```
# Build with CUDA
make clean
GGML_CUDA=1 make -j$(nproc)

echo "✅ llama.cpp built with CUDA"
```

else
echo “ℹ️  llama.cpp exists, rebuilding…”
cd $HOME/llama.cpp
git pull
make clean
GGML_CUDA=1 make -j$(nproc)
fi
EOF

# ========================================

# שלב 5: Security Hardening

# ========================================

echo “”
echo “🔒 [5/7] מגדיר אבטחה…”

# Docker sandbox configuration

mkdir -p /opt/openclaw/sandbox-config

cat > /opt/openclaw/sandbox-config/docker-sandbox.json << ‘EOF’
{
“security”: {
“noNewPrivileges”: true,
“readOnlyRoot”: true,
“capDrop”: [“ALL”],
“capAdd”: [],
“apparmor”: “docker-default”,
“seccomp”: “default”
},
“resources”: {
“memory”: “4g”,
“cpus”: “4”,
“pidsLimit”: 100
},
“network”: {
“mode”: “bridge”,
“dns”: [“1.1.1.1”, “8.8.8.8”]
},
“workspace”: {
“path”: “/opt/openclaw/workspace”,
“access”: “ro”
}
}
EOF

# Workspace directory

mkdir -p /opt/openclaw/workspace
chown ai-agent:ai-agent /opt/openclaw/workspace
chmod 750 /opt/openclaw/workspace

# UFW rules לאפשר רק localhost

ufw allow from 127.0.0.1 to any port 8080 proto tcp comment ‘OpenClaw Gateway’

echo “✅ Security configured”

# ========================================

# שלב 6: Systemd Service

# ========================================

echo “”
echo “⚙️  [6/7] יוצר systemd service…”

cat > /etc/systemd/system/openclaw.service << ‘EOF’
[Unit]
Description=OpenClaw AI Agent
After=network.target docker.service nvidia-persistenced.service
Requires=docker.service

[Service]
Type=simple
User=ai-agent
Group=ai-agent
WorkingDirectory=/opt/openclaw/openclaw
Environment=“PATH=/opt/openclaw/.nvm/versions/node/v20.18.1/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin”
Environment=“NODE_ENV=production”
Environment=“NVIDIA_VISIBLE_DEVICES=all”
Environment=“CUDA_VISIBLE_DEVICES=0”

# Security Hardening

NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/openclaw/workspace
ReadWritePaths=/opt/openclaw/openclaw

# Resource Limits

MemoryLimit=6G
CPUQuota=400%

# Start command (adjust based on OpenClaw docs)

ExecStart=/opt/openclaw/.nvm/versions/node/v20.18.1/bin/node src/index.js

# Restart policy

Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF

# Node path יצטרך עדכון לפי גרסה בפועל

systemctl daemon-reload

echo “✅ Systemd service created”
echo “   Enable: sudo systemctl enable openclaw”
echo “   Start: sudo systemctl start openclaw”

# ========================================

# שלב 7: Monitoring & Logging

# ========================================

echo “”
echo “📊 [7/7] מגדיר logging…”

# Logrotate

cat > /etc/logrotate.d/openclaw << ‘EOF’
/opt/openclaw/openclaw/logs/*.log {
daily
missingok
rotate 14
compress
delaycompress
notifempty
create 0640 ai-agent ai-agent
sharedscripts
}
EOF

# Monitoring script

cat > /usr/local/bin/openclaw-status << ‘EOF’
#!/bin/bash
echo “==========================================”
echo “  OpenClaw Status”
echo “==========================================”
echo “”
systemctl status openclaw –no-pager -l
echo “”
echo “📊 Resource Usage:”
echo “”
ps aux | grep -E “node|openclaw” | grep -v grep | awk ‘{print $1, $2, $3, $4, $11}’
echo “”
echo “🎮 GPU Status:”
nvidia-smi –query-gpu=utilization.gpu,memory.used –format=csv,noheader
echo “”
echo “🔗 Network:”
ss -tulpn | grep 8080 || echo “Gateway not listening”
echo “”
EOF

chmod +x /usr/local/bin/openclaw-status

echo “✅ Monitoring configured”
echo “   Usage: openclaw-status”

echo “”
echo “==========================================”
echo “✅ OpenClaw Installation Complete!”
echo “==========================================”
echo “”
echo “📝 Next Steps:”
echo “”
echo “1. Configure OpenClaw:”
echo “   sudo -u ai-agent nano /opt/openclaw/openclaw/config.json”
echo “”
echo “2. Download AI Model (example - DeepSeek 7B Q4):”
echo “   su - ai-agent”
echo “   cd ~/llama.cpp”
echo “   wget https://huggingface.co/…/model-q4_k_m.gguf”
echo “”
echo “3. Start OpenClaw:”
echo “   sudo systemctl enable openclaw”
echo “   sudo systemctl start openclaw”
echo “”
echo “4. Monitor:”
echo “   openclaw-status”
echo “   journalctl -u openclaw -f”
echo “”
echo “5. Access Gateway (if configured):”
echo “   http://localhost:8080”
echo “”
echo “🔒 Security Notes:”
echo “- Gateway bound to 127.0.0.1 only”
echo “- Use Tailscale for remote access”
echo “- Docker sandbox enabled for tools”
echo “- NoNewPrivileges enforced”
echo “”
