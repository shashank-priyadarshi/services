#!/bin/bash
echo ***********************************
echo Uninstalling conflicting dependencies for Docker
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
echo ***********************************
echo Starting Docker installation
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo apt-get update
sudo apt-get install docker-compose-plugin
echo Docker and Docker compose plugin installation complete
echo Run docker run hello-world to test installation
echo ***********************************
echo Installing docker-compose, gh, tree and other dependencies
# DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
# mkdir -p $DOCKER_CONFIG/cli-plugins
# curl -SL https://github.com/docker/compose/releases/download/v2.19.1/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
# sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo apt install gh tree jq
echo All installations completed
echo ***********************************
# Setup environment variables using read_secrets.sh and portfolio_secrets.json
echo ***********************************
echo Logging in to GitHub and Docker Hub
mkdir -p ~/.config/gh
echo "github.com:" > ~/.config/gh/hosts.yml
echo "    oauth_token: $GITHUB_TOKEN" >> ~/.config/gh/hosts.yml
echo "    user: $GITHUB_USERNAME" >> ~/.config/gh/hosts.yml
docker login -u "$DOCKER_REPOSITORY_USERNAME" -p "$DOCKER_REPOSITORY_TOKEN"
echo ***********************************
# Call portfolio environment setup script