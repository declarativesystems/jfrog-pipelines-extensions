#!/bin/bash -e

echo "================= Adding some global settings ==================="
mkdir -p "$HOME/.ssh/"
mv /u18/config "$HOME/.ssh/"
mv /u18/90forceyes /etc/apt/apt.conf.d/
touch "$HOME/.ssh/known_hosts"
mkdir -p /etc/drydock

echo "================= Installing basic packages ================"
apt-get update
apt-get install -y \
sudo \
software-properties-common \
wget \
unzip \
curl \
openssh-client \
ftp \
gettext \
smbclient \
mercurial \
make \
tree


export JQ_VERSION=1.6*
echo "================= Adding JQ $JQ_VERSION ========================="
apt-get install -y -q jq="$JQ_VERSION"

echo "================= Installing CLIs packages ======================"

export GIT_VERSION=1:2.*
echo "================= Installing Git $GIT_VERSION ===================="
add-apt-repository ppa:git-core/ppa -y
apt-get update -qq
apt-get install -y -q git="$GIT_VERSION"

export CLOUD_SDKREPO=274.0*
#echo "================= Adding gcloud $CLOUD_SDK_REPO =================="
#CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
#echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list
#curl -sS https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
#sudo apt-get update && sudo apt-get -y install google-cloud-sdk="$CLOUD_SDKREPO"

AWS_CLI_VERSION="2.0.59"
AWS_CLI_FILENAME="awscli-exe-linux-x86_64-${AWS_CLI_VERSION}.zip"
curl -O "https://awscli.amazonaws.com/${AWS_CLI_FILENAME}"
unzip "$AWS_CLI_FILENAME"
./aws/install
#echo "================= Adding awscli $AWS_VERSION ===================="
#sudo pip install awscli=="$AWS_VERSION"

#export AWSEBCLI_VERSION=3.17.0
#echo "================= Adding awsebcli $AWSEBCLI_VERSION =============="
#sudo pip install awsebcli=="$AWSEBCLI_VERSION"

AZURE_CLI_VERSION=2.0*
echo "================ Adding azure-cli $AZURE_CLI_VERSION =============="
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
sudo tee /etc/apt/sources.list.d/azure-cli.list
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get install -q apt-transport-https
sudo apt-get update && sudo apt-get install -y -q azure-cli=$AZURE_CLI_VERSION

JFROG_VERSION=1.39.7
echo "================= Adding jfrog-cli $JFROG_VERSION  ================"
wget -nv https://api.bintray.com/content/jfrog/jfrog-cli-go/"$JFROG_VERSION"/jfrog-cli-linux-amd64/jfrog?bt_package=jfrog-cli-linux-amd64 -O jfrog
sudo chmod +x jfrog
mv jfrog /usr/bin/jfrog

#KUBECTL_VERSION=1.16.4
#echo "================= Adding kubectl $KUBECTL_VERSION ======================================"
#curl -sSLO https://storage.googleapis.com/kubernetes-release/release/v"$KUBECTL_VERSION"/bin/linux/amd64/kubectl
#chmod +x ./kubectl
#sudo mv ./kubectl /usr/local/bin/kubectl

HELM_VERSION=2.16.1
echo "================= Adding helm cli $HELM_VERSION ======================================"
curl -sSL -o helm.tar.gz https://get.helm.sh/helm-v"$HELM_VERSION"-linux-amd64.tar.gz
tar xzvf helm.tar.gz
chmod +x ./linux-amd64/helm
chmod +x ./linux-amd64/tiller
sudo mv ./linux-amd64/helm /usr/local/bin/helm
sudo mv ./linux-amd64/tiller /usr/local/bin/tiller
rm -fr ./linux-amd64
rm -f helm.tar.gz

TF_VERSION=0.12.18
echo "================ Adding terraform- $TF_VERSION  ===================="
TF_FILE=terraform_"$TF_VERSION"_linux_amd64.zip

echo "Fetching terraform"
echo "-----------------------------------"
rm -rf /tmp/terraform
mkdir -p /tmp/terraform
wget -nv https://releases.hashicorp.com/terraform/$TF_VERSION/$TF_FILE
unzip -o $TF_FILE -d /tmp/terraform
sudo chmod +x /tmp/terraform/terraform
mv /tmp/terraform/terraform /usr/bin/terraform

PK_VERSION=1.5.0
echo "================ Adding packer $PK_VERSION  ===================="
PK_FILE=packer_"$PK_VERSION"_linux_amd64.zip

echo "Fetching packer"
echo "-----------------------------------"
rm -rf /tmp/packer
mkdir -p /tmp/packer
wget -nv https://releases.hashicorp.com/packer/$PK_VERSION/$PK_FILE
unzip -o $PK_FILE -d /tmp/packer
sudo chmod +x /tmp/packer/packer
mv /tmp/packer/packer /usr/bin/packer

#export ANSIBLE_VERSION=2.9.2
#echo "================ Adding ansible $ANSIBLE_VERSION =============================="
#sudo pip install ansible=="$ANSIBLE_VERSION"


PODMAN_VERSION="2.1.1~2"
echo "================ podman $PODMAN_VERSION =============================="
. /etc/os-release
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key | sudo apt-key add -
apt-get update
apt-get -y upgrade
apt-get -y install podman="$PODMAN_VERSION"
sed -i 's/driver = ""/driver = "vfs"/' /etc/containers/storage.conf

GORELEASER_VERSION=v0.145.0
echo "================ GoReleaser $GORELEASER_VERSION =============================="
curl -LO https://github.com/goreleaser/goreleaser/releases/download/v0.145.0/goreleaser_amd64.deb
dpkg -i goreleaser_amd64.deb