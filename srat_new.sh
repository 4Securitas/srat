#!/bin/bash

#######################################################################
#Script Name    :    srat.sh
#Description    :    Script used to add/modify Sigma Rules in ACSIA SOS
#Args           :    NA
#Author         :    Claudio Proietti - Dectar © 2024
#Email          :    claudio.proietti@dectar.com
#Version        :    2.0
#Date           :    21/05/2024
#######################################################################

VERSION="2.0"
RED="\e[31m"
GREEN="\e[32m"
MAGENTA="\e[35m"
YELLOW="\e[33m"
CYAN="\e[36m"
ENDCOLOR="\e[0m"

check-uuid() {
# THIS FUNCTION WILL CHECK IF THE UUID IS VALID OR NOT
  regex_uuid='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89ABab][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
  if [[ $tenant_id =~ $regex_uuid ]]; then
    printf "\n${GREEN}VALID UUID!${ENDCOLOR}\n"
    return 0
  else
    printf "\n${RED}INVALID UUID!${ENDCOLOR}\n"
    return 1
  fi
}

add-mod-sr() {
  # THIS FUNCTION IS USED TO BACKUP THE SIGMA RULES OF A SPECIFIC TENANT
  while true; do
    printf "\n${YELLOW}SELECT AN OPTION:\n\n"
    printf "1) IMPORT A SINGLE SIGMA RULE\n"
    printf "2) IMPORT ALL RULES IN A TENANT\n"
    printf "3) IMPORT ALL RULES IN EVERY TENANT\n"
    printf "0) MAIN MENU${ENDCOLOR}\n\n"
    read -p $'\e[33mInsert your option number: \e[0m' backup_option
    case $backup_option in
      1)
        read -p $'\n\e[33mEnter Tenant ID: \e[0m' tenant_id
        check-uuid "$tenant_id"
        if [ $? -eq 1 ]; then
          return
        fi
        import-single-rule "$tenant_id"
        if [ $? -eq 0 ]; then
          restart_stage_services
        fi
        ;;
      2)
        read -p $'\n\e[33mEnter Tenant ID: \e[0m' tenant_id
        check-uuid "$tenant_id"
        if [ $? -eq 1 ]; then
          return
        fi
        import_all_tenant_rules "$tenant_id"
        if [ $? -eq 0 ]; then
          restart_stage_services
        fi
        ;;
      3)
        import_all_tenants_rules
        if [ $? -eq 0 ]; then
          restart_stage_services
        fi
        ;;
      0)
        return
        ;;
      *)
        printf "\n${RED}Wrong option selected! Try again.${ENDCOLOR}\n\n"
        ;;
    esac
  done
}

import-single-rule() {
  # THIS FUNCTION IS USED TO ADD OR MODIFY A SIGMA RULE
  local tenant_id=$1
  printf "\n${CYAN}HERE IS THE SIGMA RULE THAT YOU WILL IMPORT:\n"
  printf "\n***************************************************${ENDCOLOR}\n\n"
  cat ./sigma.yaml
  printf "\n${CYAN}***************************************************${ENDCOLOR}\n\n"
  read -p $'\e[31mDo you want to import the sigma rule? (Y/N): \e[0m' confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || return
  printf "\n${CYAN}IMPORTING THE SIGMA RULE...${ENDCOLOR}\n\n"
  post_result=$(curl -v -o /dev/null -w "%{http_code}" -s -X POST -H "Content-Type: text/plain" --data-binary "@sigma.yaml" http://localhost:8110/rule/$tenant_id/STAGE2/yaml)
  if [ $post_result == "201" ]; then
      printf "\n${GREEN}IMPORT COMPLETED!${ENDCOLOR} Result: $post_result\n"
      return 0
  else
      printf "\n${RED}IMPORT FAILED!${ENDCOLOR} Error: $post_result\n"
      return 1
  fi
}

import_all_tenant_rules() {
  return 0
}

import_all_tenants_rules() {
  return 0
}

bck-sr() {
  # THIS FUNCTION IS USED TO BACKUP THE SIGMA RULES OF A SPECIFIC TENANT
  while true; do
    printf "\n${YELLOW}SELECT AN OPTION:\n\n"
    printf "1) BACKUP A SINGLE SIGMA RULE\n"
    printf "2) BACKUP ALL RULES IN A TENANT\n"
    printf "3) BACKUP ALL RULES IN EVERY TENANT\n"
    printf "0) MAIN MENU${ENDCOLOR}\n\n"
    read -p $'\e[33mInsert your option number: \e[0m' backup_option
    case $backup_option in
      1)
        read -p $'\n\e[33mEnter Tenant ID: \e[0m' tenant_id
        check-uuid "$tenant_id"
        if [ $? -eq 1 ]; then
          return 1
        fi
        read -p $'\n\e[33mEnter Rule ID: \e[0m' rule_id
        check-uuid "$rule_id"
        if [ $? -eq 1 ]; then
          return 1
        fi
        timestamp=$(date +%d-%m-%Y_%H-%M-%S)
        create_backup_dir "$tenant_id" "$timestamp"
        backup_single_rule "$tenant_id" "$rule_id" "$timestamp"
        ;;
      2)
        read -p $'\n\e[33mEnter Tenant ID: \e[0m' tenant_id
        check-uuid "$tenant_id"
        if [ $? -eq 1 ]; then
          return 1
        fi
        timestamp=$(date +%d-%m-%Y_%H-%M-%S)
        create_backup_dir "$tenant_id" "$timestamp"
        backup_all_tenant_rules "$tenant_id" "$timestamp"
        ;;
      3)
        timestamp=$(date +%d-%m-%Y_%H-%M-%S)
        backup_all_tenants_rules "$timestamp"
        ;;
      0)
        return 1
        ;;
      *)
        printf "\n${RED}Wrong option selected! Try again.${ENDCOLOR}\n\n"
        ;;
    esac
  done
}

create_backup_dir() {
  # FUNCTION THAT CREATE THE BACKUP FOLDER
  local tenant_id=$1
  local timestamp=$2
  mkdir -p backups/$tenant_id/$timestamp
  return 0
}

backup_single_rule() {
  # FUNCTION TO BACKUP A SINGLE RULE
  local tenant_id=$1
  local rule_id=$2
  local timestamp=$3
  get_result=$(curl -v -o /dev/null -w "%{http_code}" -s -X GET http://localhost:8110/rule/$tenant_id/$rule_id)
  if [ $get_result == "200" ]; then
      printf "\n${GREEN}FOUND RULE: $rule_id IN TENANT: $tenant_id!${ENDCOLOR}\n\n"
      curl -s -X GET -H "Content-Type: text/plain" http://localhost:8110/rule/$tenant_id/$rule_id | jq -r '.ruleJson' | yq -p json -o yaml - > backups/$tenant_id/$timestamp/$rule_id
      printf "\n${GREEN}BACKUP OF RULE: $rule_id COMPLETED!${ENDCOLOR}\n"
      return 0
  else
      show_logs
      printf "\n${RED}RULE NOT FOUND: $rule_id IN TENANT: $tenant_id!${ENDCOLOR} ERROR: $get_result\n"
      printf "\n${RED}OPERATION FAILED!${ENDCOLOR}\n"
      return 1
  fi
}

backup_all_tenant_rules() {
  # FUNCTION TO BACKUP ALL RULES IN A TENANT
  local tenant_id=$1
  local timestamp=$2
  for rule_id in $(curl -s -X GET -H "Content-Type: text/plain" http://localhost:8110/rule | jq -r ".rules[] | select(.tenantId == \"$tenant_id\") | .ruleId"); do
    printf "\n${CYAN}BACKING UP RULE: $rule_id ${ENDCOLOR}\n"
    backup_single_rule "$tenant_id" "$rule_id" "$timestamp"
  done
  printf "\n${GREEN}BACKUP OF ALL THE RULES IN THE TENANT: $tenant_id COMPLETED!${ENDCOLOR}\n"
  return 0
}

backup_all_tenants_rules() {
  # FUNCTION TO BACKUP ALL RULES IN EVERY TENANT
  local timestamp=$1
  read -p $'\n\e[33mDo you want to continue backing up all rules? This may take some time (Y/N): \e[0m' confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || return
  for tenant_id in $(curl -s -X GET -H "Content-Type: text/plain" http://localhost:8110/rule | jq -r '.rules[].tenantId' | sort -u); do
    create_backup_dir "$tenant_id" "$timestamp"
    for rule_id in $(curl -s -X GET -H "Content-Type: text/plain" http://localhost:8110/rule | jq -r ".rules[] | select(.tenantId == \"$tenant_id\") | .ruleId"); do
      printf "\n${CYAN}BACKING UP RULE: $rule_id IN TENANT: $tenant_id${ENDCOLOR}\n"
      backup_single_rule "$tenant_id" "$rule_id" "$timestamp"
    done
  done
  printf "\n${GREEN}BACKUP OF ALL RULES IN EVERY TENANT COMPLETED!${ENDCOLOR}\n"
  return 0
}

show_logs() {
# FUNCTION TO SHOW STAGE SERVICE LOGS
printf "\n${CYAN}SHOWING STAGE SERVICE LOGS...${ENDCOLOR}\n"
docker logs --tail 30 xdrplus-stage-services
if [ $? -eq 0 ]; then
    printf "\n${GREEN}OPERATION COMPLETED!${ENDCOLOR}\n"
    return 0
else
    printf "\n${RED}OPERATION FAILED!${ENDCOLOR}\n"
    return 1
fi
}

del-sr() {
  # THIS FUNCTION IS USED TO BACKUP THE SIGMA RULES OF A SPECIFIC TENANT
  while true; do
    printf "\n${YELLOW}SELECT AN OPTION:\n\n"
    printf "1) DELETE A SINGLE SIGMA RULE\n"
    printf "2) DELETE ALL RULES IN A TENANT\n"
    printf "3) DELETE ALL RULES IN EVERY TENANT\n"
    printf "0) MAIN MENU${ENDCOLOR}\n\n"
    read -p $'\e[33mInsert your option number: \e[0m' backup_option
    case $backup_option in
      1)
        read -p $'\n\e[33mEnter Tenant ID: \e[0m' tenant_id
        check-uuid "$tenant_id"
        if [ $? -eq 1 ]; then
          return 1
        fi
        read -p $'\n\e[33mEnter Rule ID: \e[0m' rule_id
        check-uuid "$rule_id"
        if [ $? -eq 1 ]; then
          return 1
        fi
        timestamp=$(date +%d-%m-%Y_%H-%M-%S)
        create_backup_dir "$tenant_id" "$timestamp"
        backup_single_rule "$tenant_id" "$rule_id" "$timestamp"
        delete_single_rule "$tenant_id" "$rule_id"
        if [ $? -eq 0 ]; then
          restart_stage_services
        fi
        ;;
      2)
        read -p $'\n\e[33mEnter Tenant ID: \e[0m' tenant_id
        check-uuid "$tenant_id"
        if [ $? -eq 1 ]; then
          return 1
        fi
        timestamp=$(date +%d-%m-%Y_%H-%M-%S)
        create_backup_dir "$tenant_id" "$timestamp"
        backup_all_tenant_rules "$tenant_id" "$timestamp"
        delete_all_tenant_rules "$tenant_id"
        if [ $? -eq 0 ]; then
          restart_stage_services
        fi
        ;;
      3)
        timestamp=$(date +%d-%m-%Y_%H-%M-%S)
        create_backup_dir "$tenant_id" "$timestamp"
        backup_all_tenants_rules "$timestamp"
        delete_all_tenants_rules
        if [ $? -eq 0 ]; then
          restart_stage_services
        fi
        ;;
      0)
        return 1
        ;;
      *)
        printf "\n${RED}Wrong option selected! Try again.${ENDCOLOR}\n\n"
        ;;
    esac
  done
}

delete_single_rule() {
  # FUNCTION TO DELETE A RULE
  local tenant_id=$1
  local rule_id=$2
  post_result=$(curl -v -o /dev/null -w "%{http_code}" -s -X DELETE http://localhost:8110/rule/$tenant_id/$rule_id)
  if [ $post_result == "200" ]; then
      printf "\n${GREEN}DELETE COMPLETED FOR RULE: $rule_id IN TENANT: $tenant_id!${ENDCOLOR}\n\n"
      return 0
  else
      show_logs
      printf "\n${RED}DELETE FAILED FOR RULE: $rule_id IN TENANT: $tenant_id!${ENDCOLOR} ERROR: $post_result\n"
      return 1
  fi
}

delete_all_tenant_rules() {
  # FUNCTION TO DELETE ALL RULES IN EVERY TENANT
  local tenant_id="$1"
  read -p $'\n\e[33mDo you want to continue deleting all rules in a tenant? This may take some time and a backup will be performed (Y/N): \e[0m' confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || return 1
  TIMESTAMP=$(date +%d-%m-%Y_%H-%M-%S)
  for rule_id in $(curl -s -X GET -H "Content-Type: text/plain" http://localhost:8110/rule | jq -r ".rules[] | select(.tenantId == \"$tenant_id\") | .ruleId"); do
    delete_single_rule "$tenant_id" "$rule_id"
  done
  printf "\n${GREEN}DELETION OF ALL THE RULES IN THE TENANT: $tenant_id COMPLETED!${ENDCOLOR}\n"
  return 0
}

delete_all_tenants_rules() {
  # FUNCTION TO DELETE ALL RULES IN EVERY TENANT
  read -p $'\n\e[33mDo you want to continue deleting all rules? This may take some time and a backup will be performed (Y/N): \e[0m' confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || return 1
  TIMESTAMP=$(date +%d-%m-%Y_%H-%M-%S)
  for tenant_id in $(curl -s -X GET -H "Content-Type: text/plain" http://localhost:8110/rule | jq -r '.rules[].tenantId' | sort -u); do
    for rule_id in $(curl -s -X GET -H "Content-Type: text/plain" http://localhost:8110/rule | jq -r ".rules[] | select(.tenantId == \"$tenant_id\") | .ruleId"); do
      delete_single_rule "$tenant_id" "$rule_id"
    done
  done
  printf "\n${GREEN}DELETION OF ALL THE RULES IN EVERY TENANT COMPLETED!${ENDCOLOR}\n"
  return 0
}

show_logs() {
  # FUNCTION TO SHOW STAGE SERVICE LOGS
  printf "\n${CYAN}SHOWING STAGE SERVICE LOGS...${ENDCOLOR}\n"
  docker logs --tail 30 xdrplus-stage-services
  if [ $? -eq 0 ]; then
      printf "\n${GREEN}OPERATION COMPLETED!${ENDCOLOR}\n"
      return 0
  else
      printf "\n${RED}OPERATION FAILED!${ENDCOLOR}\n"
      return 1
  fi
}

restart_stage_services() {
  # FUNCTION TO RESTART STAGE SERVICES
  printf "\n${CYAN}RESTARTING STAGE SERVICE...${ENDCOLOR}\n"
  docker restart xdrplus-stage-services
  if [ $? -eq 0 ]; then
      printf "\n${GREEN}OPERATION COMPLETED!${ENDCOLOR}\n"
      return 0
  else
      printf "\n${RED}OPERATION FAILED!${ENDCOLOR}\n"
      return 1
  fi
}

uuid() {
  # THIS FUNCTION IS USED TO CLEAR THE SCREEN
  uuidgen | tr 'A-Z' 'a-z'
  printf "\n${GREEN}UUID GENERATED!${ENDCOLOR}\n"
  return 0
}

cls() {
  # THIS FUNCTION IS USED TO CLEAR THE SCREEN
  clear
}

show_menu() {
  # THIS FUNCTION WILL SHOW THE MAIN MENU
  printf "\n${MAGENTA}SIGMA RULES AUTOMATED TOOL by Dectar - Version $VERSION${ENDCOLOR}\n\n"
  printf "SELECT AN OPTION:\n\n"
  printf "1) IMPORT OR MODIFY A SIGMA RULE\n"
  printf "2) DELETE AN EXISTING SIGMA RULE\n"
  printf "3) BACKUP EXISTING SIGMA RULES\n"
  printf "4) GENERATE A NEW RANDOM UUID v4\n"
  printf "5) CLEAR THE SCREEN\n"
  printf "0) EXIT\n\n"
}

cls
while true; do
  show_menu
  read -p $'\e[33mInsert your option number: \e[0m' choice
  case $choice in
    1)
      printf "\n${CYAN}IMPORT OR MODIFY A SIGMA RULE...${ENDCOLOR}\n"
      add-mod-sr
      ;;
    2)
      printf "\n${CYAN}DELETE A SIGMA RULE...${ENDCOLOR}\n"
      del-sr
      ;;
    3)
      printf "\n${CYAN}BACKUP SIGMA RULES...${ENDCOLOR}\n"
      bck-sr
      ;;
    4)
      printf "\n${CYAN}GENERATING A NEW RANDOM UUID v4...${ENDCOLOR}\n\n"
      uuid
      ;;
    5)
      cls
      ;;
    0)
      printf "\n${GREEN}Exiting...${ENDCOLOR}\n\n"
      exit 0
      ;;
    *)
      printf "\n${RED}Wrong option selected! Try again.${ENDCOLOR}\n\n"
      ;;
  esac
done
