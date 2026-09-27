#!/bin/bash
set -euo pipefail

if ! command -v uuidgen >/dev/null 2>&1; then 
    echo "Install uuidgen..."
    apt install uuid-runtime -y
fi 

if ! command -v hysteria >/dev/null 2>&1; then 
    echo "Install hysteria..."
    bash <(curl -fsSL https://get.hy2.sh/)
fi

if ! command -v caddy >/dev/null 2>&1; then
    echo "Install caddy..."
    apt install caddy -y 
fi 

PASSWORD=$(uuidgen)
OBS_PASS=$(uuidgen)
CLIENT_KEY={{CLIENT_KEY}}

cat > ./server.yaml << EOF 
listen: :443

acme:
  domains:
    - random.drrr-sy.top
  email: hongsy2020@foxmail.com

auth:
  type: password
  password: ${PASSWORD}

masquerade:
  type: proxy
  proxy:
    url: https://www.microsoft.com
    rewriteHost: true
  listenHTTP: :80
  listenHTTPS: :443
  forceHTTPS: true

obfs:
  type: salamander
  salamander:
    password: ${OBS_PASS} 

EOF

sed -e "s|{{PASSWORD}}|$PASSWORD|g" \
    -e "s|{{OBFS_PWD}}|$OBS_PASS|g" \
    client.yaml > client_new.yaml

mkdir -pv /var/www/sub

mv ./server.yaml /etc/hysteria/config.yaml && echo "Update Success!"
systemctl restart hysteria-server.service && echo "Restart Success!"


mv ./client_new.yaml "/var/www/sub/${CLIENT_KEY}.yaml"

mkdir -pv /etc/caddy/certs 
cp /var/lib/hysteria/acme/certificates/acme-v02.api.letsencrypt.org-directory/random.drrr-sy.top/random.drrr-sy.top.crt /etc/caddy/certs 
cp /var/lib/hysteria/acme/certificates/acme-v02.api.letsencrypt.org-directory/random.drrr-sy.top/random.drrr-sy.top.key /etc/caddy/certs 
chown root:caddy /etc/caddy/certs/*
chmod 640 /etc/caddy/certs/*

cat > /etc/caddy/Caddyfile << EOF 
{
    auto_https disable_redirects
}

https://random.drrr-sy.top:8443 {
    tls /etc/caddy/certs/random.drrr-sy.top.crt /etc/caddy/certs/random.drrr-sy.top.key
    handle_path /sub/* {
        root * /var/www/sub
        file_server
    }
}

EOF

caddy validate --config /etc/caddy/Caddyfile
systemctl restart caddy

