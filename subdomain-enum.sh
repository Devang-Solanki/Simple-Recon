#!/bin/bash

NC='\033[0m'              # No Color
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue

echo -e "${Yellow}[*] Finding all subdomain and storing it in all_subdomain.txt\n${NC}"

#Subdomains from subfinder
echo -e "${Blue}Running Subfinder\n${NC}"

subfinder -all -dL $1 -o "/tmp/subf_$1"  -silent

#Subdomains from amass
echo -e "\n${Blue}Running Amass"

amass enum -passive -df $1 -src -config ~/.config/amass/config.ini -silent -o "/tmp/amass_$1" 

#Subdomains from findomain
echo -e "\n${Blue}Running Findomain${NC}"

findomain -f $1 -u "/tmp/find_$1"

#Subdomains from gauplus
echo -e "${Blue}Running Gauplus for subdomain\n${NC}"

cat $1 | gauplus -subs | unfurl -u domains | tee -a "/tmp/gau_$1"

echo -e "\n${Yellow}[*] Prcosessing all files generated from tools\n${NC}"

#Fomating files from amass for combining
cat /tmp/ww.txt | cut -f 2 -d ']' | sed 's/ //g' | tee -a "/tmp/amass_final_$1"

#Combining all the files
echo -e "\n${Blue}Combining all the files\n${NC}"

cat "/tmp/subf_$1" "/tmp/find_$1" "/tmp/amass_final_$1" "/tmp/gau_$1" | sort -u | tee -a "$PWD/all_subdomain.txt"

#Running httpx for all status code
echo -e "\n${Yellow}[*] Running httpx and sorting domains based on status code\n${NC}"

httpx -l "$PWD/all_subdomain.txt" -title -status-code -tech-detect -no-color -o "$PWD/httpx_url.txt"

#Sorting 200,301,302 etc live domains
echo -e "\n${Blue}Sorting all 20x,30x etc live domains\n${NC}"

sed -e "/[23][0-9][0-9]/{w $PWD/live.txt" -e 'd}' "$PWD/httpx_url.txt"

#Sorting 404 for possible subdomain takeover
echo -e "\n${Blue}Sorting 404 for possible subdomain takeover\n${NC}"
sed -e "/404/{w $PWD/404.txt" -e 'd}' "$PWD/httpx_url.txt"

#Sorting 403 domains
echo -e "\n${Blue}Sorting 403 domains\n${NC}"
sed -e "/403/{w $PWD/403.txt" -e 'd}' "$PWD/httpx_url.txt"


#Checking if all went right

echo -e "\m${Yellow}[*] Checking if all went right\n"

if [[ -f "$PWD/all_subdomain.txt" ]]
then
    echo -e "${Green}all_subdomain.txt exist${NC}"
else
    echo -e "${RED}Something went wrong during subdomain enumeration${NC}"
    exit
fi

if [[ -f "$PWD/httpx_url.txt" ]]
then
    echo -e "${Green}httpx_url.txt exist${NC}"
else
    echo -e "${RED}Something went wrong during httpx probbing${NC}"
    exit
fi

if [[ -f "$PWD/live.txt" ]]
then
    echo -e "${Green}live.txt exist${NC}"
else
    echo -e "${RED}Something went wrong during httpx probbing or probably during sorting${NC}"
    exit
fi

if [[ -f "$PWD/403.txt" ]]
then
    echo -e "${Green}403.txt exist${NC}"
else
    echo -e "${RED}Something went wrong during httpx probbing or probably during sorting${NC}"
    exit
fi

if [[ -f "$PWD/403.txt" ]]
then
    echo -e "${Green}404.txt exist${NC}"
else
    echo -e "${RED}Something went wrong during httpx probbing or probably during sorting${NC}"
    exit
fi
