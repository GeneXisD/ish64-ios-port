#!/bin/bash

DOMAIN="ish.local.dev"
IP="192.168.0.17"
GITEA_CONF="/opt/homebrew/var/gitea/custom/conf/app.ini"

echo "Configuring domain for Gitea..."

echo "Adding domain to hosts file..."

if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "$IP    $DOMAIN" | sudo tee -a /etc/hosts
else
    echo "Hosts entry already exists."
fi

echo "Updating Gitea configuration..."

sudo sed -i '' "s|DOMAIN *=.*|DOMAIN = $DOMAIN|" $GITEA_CONF
sudo sed -i '' "s|ROOT_URL *=.*|ROOT_URL = http://$DOMAIN:3000/|" $GITEA_CONF

echo "Restarting Gitea..."

brew services restart gitea

echo ""
echo "Done."
echo "Open your server at:"
echo "http://$DOMAIN:3000"

