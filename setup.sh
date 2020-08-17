#!/bin/bash


echo "Setup Jenkins and Sonarqube on Ubuntu 18.04"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


if ! command -v java;
then
        echo -e "${RED}java is not installed, installing openjdk-java${NC}"
        sudo apt update -y
        sudo apt install default-jre -y
        sudo apt install default-jdk -y
        sudo apt install unzip

else
        echo -e " ${GREEN}java version${NC}"
        java --version

fi


if [ ! -d "/var/lib/jenkins" ];
then
        echo -e "${RED} Jenkins not present ${NC}"
        wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
        sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > \
        /etc/apt/sources.list.d/jenkins.list'
        sudo apt-get update -y

        echo -e " ${GREEN}  Installing Jenkins ${NC}"
        sudo apt-get install jenkins -y
else
        echo -e " ${GREEN} Jenkins is installed ${NC}"
fi



if ! command -v docker;
then
        echo -e " ${RED} Docker not present ${NC}"
        sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
        sudo apt update -y
        echo -e " ${GREEN} Install docker ${NC}"
        sudo apt install docker-ce -y
        echo -e " ${GREEN} add user UBUNTU to docker group ${NC}"
        sudo usermod -aG docker ${USER}
        echo -e " ${GREEN} add user Jenkins to docker group ${NC}"
        sudo usermod -aG docker jenkins
        echo -e " ${GREEN} Initialize swarm cluster, single node ${NC}"
        sudo docker swarm init
else
        echo -e " ${GREEN} Docker is Installed ${NC}"
        docker --version
fi

echo -e "${GREEN}Install python2.7 for Robot Framework${NC}"
sudo apt install python2.7 python-pip -y
pip install robotframework
pip install robotframework-httplibrary

## copy robot binary to bin
BIN_PATH=$(which robot)
sudo cp $BIN_PATH /usr/local/bin/

echo -e "${GREEN}Download Sonar scanner cli${NC}"
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.4.0.2170-linux.zip
unzip sonar-scanner-cli-4.4.0.2170-linux.zip


echo -e "${GREEN}Restart Jenkins Server${NC}"
sudo service jenkins restart

echo -e " ${GREEN}Run sonarqube server${NC}"
sudo docker run -d --name sonarqube -p 9000:9000 sonarqube
sleep 10
sudo docker exec -it sonarqube bash -c 'cd /opt/sonarqube/extensions/plugins/ && wget https://github.com/fsantiag/sonar-clojure/releases/download/v2.0.0/sonar-clojure-plugin-2.0.0.jar && chmod +x sonar-clojure-plugin-2.0.0.jar'

echo -e "${GREEN}Login into sonarqube using user & pass admin:admin${NC}\n"
echo -e "${GREEN} Install following plugins from Jenkins dashboard${NC}\n"
echo -e "${GREEN}Robot Framework plugin${NC}\n"
echo -e "${GREEN}Sonarqube Scanner for Jenkins${NC}\n"
echo -e "${GREEN}Quality Gates Plugin${NC}\n"
echo -e "${GREEN}Generic Webhook Trigger Plugin${NC}\n"
echo -e "${GREEN}Copy Artifact Plugin${NC}\n"

echo -e "${GREEN}Your jenkins initial password${NC}"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo -e "${GREEN}Setup Jenkins by logging at IP:8080${NC}"
