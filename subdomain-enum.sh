#!/bin/bash

#Settings color for pretty output
NC='\033[0m'              # No Color
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue

# Help                                                     #
############################################################

Help()
{
   # Display Help
   echo -e "${Yellow}[*] Subdomain enum script for finding subdomain and sorting on basis of status code.${NC}"
   echo
   echo -e "${Green}Syntax: subdomain-enum.sh${NC} ${Blue}[-l|h|]${NC}"
   echo -e "${Green}options:${NC}"
   echo -e "${Red}l :${NC}     ${Blue}Takes list of domain as input.${NC}"
   echo -e "${Red}h :${NC}     ${Blue}Print this Help.${NC}"
   echo
   echo -e "${Green}example subdomain-enum.sh -l example.org.txt${NC}"
}

# Getting the list of domains                              #
############################################################

Domain_list()
{
    List=$1

    if [[ -f $List && -s $List ]]
    then
         echo -e "Running script for file : $List"
    elif [[ -f $List && ! -s $List ]]
    then
         echo -e "${Red}Error :${NC} File $List seems to be empty"
         exit
    else
         echo -e "${Red}Error :${NC} File $List does not exist"
	 exit
    fi

}

# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts "hl:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      l) # Getting the list of domains
      	 File=$OPTARG;;
      \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

Domain_list "$File"

# Checking if all tools are installed properly             #
############################################################

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



# Checking if its running for second time                  #
# Building the env                                         #
############################################################

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

# Function for getting the list of domains from recon.cloud #
#############################################################

Recon_cloud()
{
    Domain=$1
    curl -s "https://recon.cloud/api/search?domain=$Domain" --output "/tmp/ans_$Domain.json"

    Req_id=$(jq -r '.request_id' "/tmp/ans_$Domain.json")
    Len=$(jq '.assets.assets | length' "/tmp/ans_$Domain.json")

    if [[ $Req_id = "None"  ]]
    then
        if [ $Len -gt 0 ]
        then
            jq -r '.assets.assets[] | .domain + " " + .service + " "  + .region + " "  + .cname' "/tmp/ans_$Domain.json" | tee -a recon.cloud.txt
        fi
    else
        while true; do
            curl -s "https://recon.cloud/api/get_status?request_id=$Req_id" --output "/tmp/status_$Domain.json"
            Status=$(jq -r '.status.stage' "/tmp/status_$Domain.json")
            if [ $Status = "finished" ]
            then
            curl -s "https://recon.cloud/api/get_results?request_id=$Req_id" --output "/tmp/result_$Domain.json"
            jq -r '.assets[] | .domain + " " + .service + " "  + .region + " "  + .cname' "/tmp/result_$Domain.json" | tee -a recon.cloud.txt
            break
            fi
            sleep 3
        done
    fi
}

# Finding all subdomain and storing it in all_subdomain.txt #
#############################################################

echo -e "${Yellow}[*] Finding all subdomain and storing it in all_subdomain.txt\n${NC}"

# Subdomains from subfinder
echo -e "${Blue}Running Subfinder\n${NC}"

subfinder -all -dL $List -o "/tmp/subf_$List"  -silent

# Subdomains from amass
echo -e "\n${Blue}Running Amass"

amass enum -passive -df $List -src -config ~/.config/amass/config.ini -silent -o "/tmp/amass_$List" 

# Subdomains from findomain
echo -e "\n${Blue}Running Findomain${NC}"

findomain -f $List -u "/tmp/find_$List"

# Subdomains from gauplus
echo -e "${Blue}Running Gauplus for subdomain\n${NC}"

cat $List | gauplus -subs | unfurl -u domains | tee -a "/tmp/gau_$List"

echo -e "\n${Yellow}[*] Prcosessing all files generated from tools\n${NC}"

# Fomating files from amass for combining
cat "/tmp/amass_$List" | cut -f 2 -d ']' | sed 's/ //g' | tee -a "/tmp/amass_final_$List"

# Combining all the files
echo -e "\n${Blue}Combining all the files\n${NC}"

cat "/tmp/subf_$List" "/tmp/find_$List" "/tmp/amass_final_$List" "/tmp/gau_$List" | sort -u | tee -a "$PWD/all_subdomain.txt"

# Running httpx for all status code                         #
############################################################

echo -e "\n${Yellow}[*] Running httpx and sorting domains based on status code\n${NC}"

httpx -l "$PWD/all_subdomain.txt" -title -status-code -tech-detect -no-color -o "$PWD/httpx_url.txt"

# Sorting 200,301,302 etc live domains
echo -e "\n${Blue}Sorting all 20x,30x etc live domains\n${NC}"

sed -e "/[23][0-9][0-9]/{w $PWD/live.txt" -e 'd}' "$PWD/httpx_url.txt"

# Sorting 404 for possible subdomain takeover
echo -e "\n${Blue}Sorting 404 for possible subdomain takeover\n${NC}"
sed -e "/404/{w $PWD/404.txt" -e 'd}' "$PWD/httpx_url.txt"

# Sorting 403 domains
echo -e "\n${Blue}Sorting 403 domains\n${NC}"
sed -e "/403/{w $PWD/403.txt" -e 'd}' "$PWD/httpx_url.txt"
