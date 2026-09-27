PASSWORD=$(uuidgen)
OBS_PASS=$(uuidgen)

if ! command -v uuidgen >/dev/null 2>&1; then 
    echo "Install uuidgen..."
    apt install uuid-runtime -y
fi 

if ! command -v hysteria >/dev/null 2>&1; then 
    echo "Install hysteria..."
    bash <(curl -fsSL https://get.hy2.sh/)
fi 

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


mv ./server.yaml /etc/hysteria/config.yaml && echo "Update Success!"
systemctl restart hysteria-server.service && echo "Restart Success!"
