#!/bin/bash

#######################################################################
#Script Name	:    srat.sh                                                                                              
#Description	:    Script used to add/modify Sigma Rules in ACSIA SOS                                                                             
#Args           :    NA                                                                                           
#Author       	:    Claudio Proietti - Dectar © 2024                                                
#Email         	:    claudio.proietti@dectar.com
#Version        :    1.0
#Date           :    16/04/2024
#######################################################################

VERSION="1.0" 
RED="\e[31m"
GREEN="\e[32m"
MAGENTA="\e[35m"
YELLOW="\e[33m"
CYAN="\e[36m"
ENDCOLOR="\e[0m"

add-mod-sr() {
  # THIS FUNCTION IS USED TO ADD OR MODIFY A SIGMA RULE
  read -p $'\n\e[33mEnter Tenant ID: \e[0m' tenant_id
  regex_uuid='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89ABab][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
  if [[ $tenant_id =~ $regex_uuid ]]; then
    printf "\n${GREEN}VALID UUID!${ENDCOLOR}\n"
  else
    printf "\n${RED}INVALID UUID!${ENDCOLOR}\n"
    return
  fi
  printf "\n${CYAN}HERE IS THE SIGMA RULE THAT YOU WILL PUSH:\n"
  printf "\n***************************************************${ENDCOLOR}\n\n"
  cat ./sigma.yaml
  printf "\n${CYAN}***************************************************${ENDCOLOR}\n\n"
  read -p $'\e[31mDo you want to push the sigma rule? (Y/N): \e[0m' confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || return
  printf "\n${CYAN}PUSHING THE SIGMA RULE...${ENDCOLOR}\n\n"
  post_result=$(curl -v -o /dev/null -w "%{http_code}" -s -X POST -H "Content-Type: text/plain" --data-binary "@sigma.yaml" http://localhost:8110/rule/$tenant_id/STAGE2/yaml)
  if [ $post_result == "201" ]; then
      printf "\n${GREEN}PUSH COMPLETED!${ENDCOLOR} Result: $post_result\n"
      printf "\n${CYAN}SHOW STAGE SERVICE LOGS...${ENDCOLOR}\n"
      docker logs --tail 30 xdrplus-stage-services
      printf "\n${CYAN}RESTART STAGE SERVICE...${ENDCOLOR}\n"
      docker restart xdrplus-stage-services
      printf "\n${GREEN}OPERATION COMPLETED!${ENDCOLOR}\n"
  else
      printf "\n${RED}PUSH FAILED!${ENDCOLOR} Error: $post_result\n"
      printf "\n${CYAN}SHOW STAGE SERVICE LOGS...${ENDCOLOR}\n"
      docker logs --tail 30 xdrplus-stage-services
      printf "\n${RED}OPERATION FAILED!${ENDCOLOR}\n" 
  fi
}

del-sr() {
  # THIS FUNCTION IS USED TO DELETE A SIGMA RULE
  read -p $'\n\e[33mEnter Tenant ID: \e[0m' tenant_id
  regex_uuid='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89ABab][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
  if [[ $tenant_id =~ $regex_uuid ]]; then
    printf "\n${GREEN}VALID UUID!${ENDCOLOR}\n"
  else
    printf "\n${RED}INVALID UUID!${ENDCOLOR}\n"
    return
  fi  
  read -p $'\n\e[33mEnter Rule ID: \e[0m' rule_id
  regex_uuid='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89ABab][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
  if [[ $rule_id =~ $regex_uuid ]]; then
    printf "\n${GREEN}VALID UUID!${ENDCOLOR}\n"
  else
    printf "\n${RED}INVALID UUID!${ENDCOLOR}\n"
    return
  fi
  read -p $'\n\e[31mAre you sure you want to delete the Sigma Rule? (Y/N): \e[0m' confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || return
  post_result=$(curl -v -o /dev/null -w "%{http_code}" -s -X DELETE http://localhost:8110/rule/$tenant_id/$rule_id)
  printf "\n${GREEN}OPERATION COMPLETED!${ENDCOLOR}\n\n"
  if [ $post_result == "200" ]; then
      printf "\n${GREEN}DELETE COMPLETED!${ENDCOLOR} Result: $post_result\n"
      printf "\n${CYAN}SHOW STAGE SERVICE LOGS...${ENDCOLOR}\n"
      docker logs --tail 30 xdrplus-stage-services
      printf "\n${CYAN}RESTART STAGE SERVICE...${ENDCOLOR}\n"
      docker restart xdrplus-stage-services
      printf "\n${GREEN}OPERATION COMPLETED!${ENDCOLOR}\n"
  else
      printf "\n${RED}DELETE FAILED!${ENDCOLOR} Error: $post_result\n"
      printf "\n${CYAN}SHOW STAGE SERVICE LOGS...${ENDCOLOR}\n"
      docker logs --tail 30 xdrplus-stage-services
      printf "\n${RED}OPERATION FAILED!${ENDCOLOR}\n"
  fi
}


uuid() {
  # THIS FUNCTION IS USED TO CLEAR THE SCREEN
  uuidgen | tr 'A-Z' 'a-z'
  printf "\n${GREEN}UUID GENERATED!${ENDCOLOR}\n"
}

cls() {
  # THIS FUNCTION IS USED TO CLEAR THE SCREEN
  clear
}

show_menu() {
  # THIS FUNCTION WILL SHOW THE MAIN MENU
  printf "\n${MAGENTA}SIGMA RULES AUTOMATED TOOL by Dectar - Version $VERSION${ENDCOLOR}\n\n"
  printf "SELECT AN OPTION:\n\n"
  printf "1) ADD OR MODIFY A SIGMA RULE\n"
  printf "2) DELETE AN EXISTING SIGMA RULE\n"
  printf "3) GENERATE A NEW RANDOM UUID v4\n"
  printf "4) CLEAR THE SCREEN\n"
  printf "0) EXIT\n\n"
}

cls
while true; do
  show_menu
  read -p $'\e[33mInsert your option number: \e[0m' choice
  case $choice in
    1)
      add-mod-sr
      printf "\n${CYAN}ADD OR MODIFY A SIGMA RULE...${ENDCOLOR}\n"
      ;;
    2)
      printf "\n${CYAN}DELETE A SIGMA RULE...${ENDCOLOR}\n"
      del-sr
      ;;
    3)
      printf "\n${CYAN}GENERATING A NEW RANDOM UUID v4...${ENDCOLOR}\n\n"
      uuid
      ;;
    4)
      cls
      ;;
    0)
      printf "\n${GREEN}Exiting...${ENDCOLOR}\n\n"
      exit 0
      ;;
    *)
      echo "Wrong option selected! Try again."
      ;;
  esac
done
