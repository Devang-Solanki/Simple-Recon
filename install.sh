#!/bin/bash

#Settings color for pretty output
NC='\033[0m'              # No Color
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue

tools=~/Tools
double_check=false
AMASS_CONFIG=~/.config/amass/config.ini

BASH_VERSION=$(bash --version | awk 'NR==1{print $4}' | cut -d'.' -f1)
if [ ${BASH_VERSION} -lt 4 ]; then
     printf "${Red} Your Bash version is lower than 4, please update${NC}\n"
fi

#Declaring go tools
declare -A gotools
gotools["Amass"]="go install -v github.com/OWASP/Amass/v3/...@master"
gotools["unfurl"]="go install -v github.com/tomnomnom/unfurl@latest"
gotools["httpx"]="go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
gotools["gauplus"]="go install github.com/bp0lr/gauplus@latest"
gotools["subfinder"]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"

#Updating GO tools
version="go1.17.6"
printf "${Blue} Running: Installing/Updating Golang ${NC}\n\n"
if [[ $(eval type go $DEBUG_ERROR | grep -o 'go is') == "go is" ]] && [ "$version" = $(go version | cut -d " " -f3) ]
    then
        printf "${Green} Golang is already installed and updated ${NC}\n\n"
else
    sudo rm -rf /usr/local/go
    wget https://dl.google.com/go/${version}.linux-amd64.tar.gz -o /tmp
    sudo tar -C /usr/local -xzf /tmp/${version}.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile

[ -n "$GOPATH" ] || { printf "${Red} GOPATH env var not detected, add Golang env vars to your \$HOME/.bashrc or \$HOME/.zshrc:\n\n export GOROOT=/usr/local/go\n export GOPATH=\$HOME/go\n export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH\n\n"; exit 1; }
[ -n "$GOROOT" ] || { printf "${Red} GOROOT env var not detected, add Golang env vars to your \$HOME/.bashrc or \$HOME/.zshrc:\n\n export GOROOT=/usr/local/go\n export GOPATH=\$HOME/go\n export PATH=\$GOPATH/bin:\$GOROOT/bin:\$PATH\n\n"; exit 1; }

#Installing GO Tools
printf "${Blue} Running: Installing Golang tools (${#gotools[@]})${NC}\n\n"
go env -w GO111MODULE=auto
go_step=0
for gotool in "${!gotools[@]}"; do
    go_step=$((go_step + 1))
    eval ${gotools[$gotool]}
    exit_status=$?
    if [ $exit_status -eq 0 ]
    then
        printf "${Yellow} $gotool installed (${go_step}/${#gotools[@]})${NC}\n"
    else
        printf "${Red} Unable to install $gotool, try manually (${go_step}/${#gotools[@]})${NC}\n"
        double_check=true
    fi
done

#Getting the config files
wget -nc -O ~/.config/amass/config.ini https://raw.githubusercontent.com/OWASP/Amass/master/examples/config.ini

# Check
if [ "$double_check" = "true" ]; then
    printf "${Blue} Running: Double check for installed tools ${NC}\n\n"
    go_step=0
    for gotool in "${!gotools[@]}"; do
        go_step=$((go_step + 1))
        eval type -P $gotool $DEBUG_STD || { eval ${gotools[$gotool]} $DEBUG_STD; }
        exit_status=$?
    done
fi

printf "${Yellow} Remember set your api keys:\n - amass (~/.config/amass/config.ini)\n - Subfinder (~/.config/subfinder/provider-config.yaml)
printf "${Green} Finished!${NC}\n\n"
