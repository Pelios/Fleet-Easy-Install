
sudo apt-get update && sudo apt-get -y upgrade
sudo apt-get install -y curl git

curl -O https://storage.googleapis.com/golang/go1.11.2.linux-amd64.tar.gz
tar -xvf go1.11.2.linux-amd64.tar.gz
sudo mv go /usr/local

sudo echo -n 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
sudo echo -e '\nexport GOPATH=$HOME/go' >> ~/.profile
source ~/.profile

mkdir go

sudo apt-get purge -y --auto-remove cmdtest
sudo apt-get install -y build-essential npm

curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install -y yarn
curl -sL https://deb.nodesource.com/setup_9.x | sudo -E bash -
sudo apt-get install -y nodejs

sudo apt-get remove docker docker-engine docker.io

sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install -y docker-ce
sudo apt-get install -y docker-compose

sudo systemctl enable docker
sudo systemctl start docker



sudo mkdir -p $GOPATH/src/github.com/kolide
cd $GOPATH/src/github.com/kolide
sudo git clone https://github.com/kolide/fleet.git
cd fleet

sudo chown -R fleet $GOPATH

make deps
make generate
make

sed -i '5i\    user: "1000:50"' docker-compose.yml


sudo docker-compose up -d

./build/fleet prepare db

sudo mkdir -p /etc/pki
sudo mkdir -p /etc/pki/tls
sudo mkdir -p /etc/pki/tls/certs
sudo mkdir -p /etc/pki/tls/private
sudo mkdir -p /var/log/kolide
sudo openssl genrsa -out /etc/pki/tls/private/server.key 4096
sudo openssl req -new -key /etc/pki/tls/private/server.key -out /etc/pki/tls/certs/server.csr
sudo openssl x509 -req -days 366 -in /etc/pki/tls/certs/server.csr -signkey /etc/pki/tls/private/server.key -out /etc/pki/tls/certs/server.cert

sudo touch /etc/systemd/system/fleet.service

echo '[Unit]
Description=Kolide Fleet Application Server
[Service]
User=fleet
WorkingDirectory=/home/fleet/go/src/github.com/kolide/fleet
Environment="PATH=/home/fleet/go/src/github.com/kolide/fleet/build/"
ExecStart=/home/fleet/go/src/github.com/kolide/fleet/build/fleet serve --config /home/fleet/go/src/github.com/kolide/fleet/kolide.yml
[Install]
WantedBy=multi-user.target' >> /etc/systemd/system/fleet.service

key=$(openssl rand -base64 32)
key=${key%?}


sudo touch /home/fleet/go/src/github.com/kolide/fleet/kolide.yml
echo "server:
cert: /etc/pki/tls/certs/server.cert
key: /etc/pki/tls/private/server.key
address: 0.0.0.0:8080
logging:
  json: true
auth:
  jwt_key: $key" >> /home/fleet/go/src/github.com/kolide/fleet/kolide.yml


sudo systemctl enable fleet
sudo systemctl start fleet







