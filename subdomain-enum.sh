#!/bin/bash

#Settings color for pretty output
NC='\033[0m'              # No Color
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue



#Checking if all tools are installed properly
echo -e "${Yellow}[*] Checking if all tools are installed properly\n${NC}"

if type amass &> /dev/null
then
    echo -e "${Green}Amass is installed\n${NC}"
#elif [[ -f ~/Desktop/Tools/findomain-linux ]]                                                                #To be decided
#then
#    echo -e "${Red}Findomain is installed but symlink is missing\n${NC}"
#    exit
else
    echo -e "${RED}Amass is not installed\n${NC}"
    exit
fi

if type subfinder &> /dev/null
then
    echo -e "${Green}Subfinder is installed\n${NC}"
elif [[ -f ~/go/bin/subfinder ]]
then
    echo -e "${Red}Subfinder is installed but symlink is missing\n${NC}"
    exit
else
    echo -e "${RED}Subfinder is not installed\n${NC}"
    exit
fi

if type gauplus &> /dev/null
then
    echo -e "${Green}Gauplus is installed\n${NC}"
elif [[ -f ~/go/bin/gauplus ]]
then
    echo -e "${Red}Gauplus is installed but symlink is missing\n${NC}"
    exit
else
    echo -e "${RED}Gauplus is not installed\n${NC}"
    exit
fi

if type unfurl &> /dev/null
then
    echo -e "${Green}Unfurl is installed\n${NC}"
elif [[ -f ~/go/bin/unfurl ]]
then
    echo -e "${Red}Unfurl is installed but symlink is missing\n${NC}"
    exit
else
    echo -e "${RED}Unfurl is not installed\n${NC}"
    exit
fi

if type httpx &> /dev/null
then
    echo -e "${Green}Httpx is installed\n${NC}"
elif [[ -f ~/go/bin/httpx ]]
then
    echo -e "${Red}Httpx is installed but symlink is missing\n${NC}"
    exit
else
    echo -e "${RED}Httpx is not installed\n${NC}"
    exit
fi



#Checking if its running for second time
#Building the env
echo -e "${Yellow}[*] Checking if its runned before\n"

if [[ ! -d "$PWD/old" ]]
then
    echo -e "${Blue}Yes moving all files to $PWD/old \n${NC}"
    mkdir "$PWD/old" &> /dev/null;
fi

if [[ -f "$PWD/all_subdomain.txt" ]]
then
    mv "$PWD/all_subdomain.txt" "$PWD/old/all_subdomain.txt";
fi

if [[ -f "$PWD/httpx_url.txt" ]]
then
    mv "$PWD/httpx_url.txt" "$PWD/old/httpx_url.txt";
fi
    
if [[ -f "$PWD/live.txt" ]]
then
    mv "$PWD/live.txt" "$PWD/old/live.txt";
fi
    
if [[ -f "$PWD/403.txt" ]]
then
    mv "$PWD/403.txt" "$PWD/old/403.txt";
fi

if [[ -f "$PWD/404.txt" ]]
then
    mv "$PWD/404.txt" "$PWD/old/404.txt";
fi


#Finding all subdomain and storing it in all_subdomain.txt
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
cat "/tmp/amass_$1" | cut -f 2 -d ']' | sed 's/ //g' | tee -a "/tmp/amass_final_$1"

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
