#!/bin/bash
# ================================================================
#   SlowDNS Installer — DevCulture XII Store VPN Premium
#   Fixed: binary URLs now use official HideSSH/slowdns releases
#          nsdomain guard added, key generation on first install
# ================================================================

HIDESSH_BASE="https://github.com/hidessh/slowdns/releases/latest/download"
ARCH="$(uname -m)"

# Map uname arch → binary suffix
case "$ARCH" in
    x86_64)  BIN_ARCH="linux-amd64"  ;;
    aarch64) BIN_ARCH="linux-arm64"  ;;
    armv7*)  BIN_ARCH="linux-armv7"  ;;
    *)       BIN_ARCH="linux-amd64"  ;;
esac

# Check nsdomain exists
if [[ ! -f /etc/xray/nsdomain ]]; then
    echo "ERROR: /etc/xray/nsdomain not found. Set your SlowDNS NS subdomain first:"
    echo "  echo 'ns.yourdomain.com' > /etc/xray/nsdomain"
    exit 1
fi
nsdomain=$(cat /etc/xray/nsdomain)

echo "Port 2222" >> /etc/ssh/sshd_config
echo "Port 2269" >> /etc/ssh/sshd_config
sed -i 's/#AllowTcpForwarding yes/AllowTcpForwarding yes/g' /etc/ssh/sshd_config
service ssh restart 2>/dev/null || service sshd restart 2>/dev/null

echo "Install SlowDNS..."
rm -rf /etc/slowdns
mkdir -m 755 /etc/slowdns

# Download sldns binaries from official releases
wget -q --timeout=30 --tries=3 \
    -O /etc/slowdns/sldns-server \
    "${HIDESSH_BASE}/sldns-server-${BIN_ARCH}" || {
    # Fallback: try without arch suffix (older releases)
    wget -q --timeout=30 --tries=3 \
        -O /etc/slowdns/sldns-server \
        "${HIDESSH_BASE}/sldns-server"
}

wget -q --timeout=30 --tries=3 \
    -O /etc/slowdns/sldns-client \
    "${HIDESSH_BASE}/sldns-client-${BIN_ARCH}" || {
    wget -q --timeout=30 --tries=3 \
        -O /etc/slowdns/sldns-client \
        "${HIDESSH_BASE}/sldns-client"
}

chmod +x /etc/slowdns/sldns-server /etc/slowdns/sldns-client

# Generate keypair if it doesn't already exist
if [[ ! -f /etc/slowdns/server.key ]] || [[ ! -f /etc/slowdns/server.pub ]]; then
    echo "Generating SlowDNS keypair..."
    /etc/slowdns/sldns-server -gen-key -privkey-file /etc/slowdns/server.key -pubkey-file /etc/slowdns/server.pub
    echo "Keypair generated."
fi

# Install client service
cat > /etc/systemd/system/client-sldns.service << END
[Unit]
Description=Client SlowDNS By HideSSH
Documentation=https://hidessh.com
After=network.target nss-lookup.target
[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/etc/slowdns/sldns-client -udp 8.8.8.8:53 --pubkey-file /etc/slowdns/server.pub ${nsdomain} 127.0.0.1:2222
Restart=on-failure
[Install]
WantedBy=multi-user.target
END

# Install server service
cat > /etc/systemd/system/server-sldns.service << END
[Unit]
Description=Server SlowDNS By HideSSH
Documentation=https://hidessh.com
After=network.target nss-lookup.target
[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/etc/slowdns/sldns-server -udp :5300 -privkey-file /etc/slowdns/server.key ${nsdomain} 127.0.0.1:2269
Restart=on-failure
[Install]
WantedBy=multi-user.target
END

chmod 644 /etc/systemd/system/client-sldns.service
chmod 644 /etc/systemd/system/server-sldns.service

pkill sldns-server 2>/dev/null
pkill sldns-client 2>/dev/null

systemctl daemon-reload
systemctl enable client-sldns server-sldns
systemctl restart client-sldns server-sldns

sleep 1
for svc in client-sldns server-sldns; do
    if systemctl is-active --quiet "$svc"; then
        echo "[  OK  ] $svc is running"
    else
        echo "[ WARN ] $svc failed — check: journalctl -u $svc"
    fi
done
