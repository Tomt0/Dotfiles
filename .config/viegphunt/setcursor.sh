#!/usr/bin/env bash

mkdir -p ~/.icons/default/
cat > ~/.icons/default/index.theme << 'EOF'
[icon theme]
Inherits=Moga-Neon-Cyan
EOF
sudo mkdir -p /usr/share/icons/default/
sudo cp ~/.icons/default/index.theme /usr/share/icons/default/
