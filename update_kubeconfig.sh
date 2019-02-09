#!/usr/bin/env /bin/bash

#Pre-requisites
# gardenctl, kubectl, sponge, az CLI

function list_gardens() {
  gardenctl ls gardens | awk '{print $3}' | sed '/^$/d'
}

function target_garden() {
  echo ""
  echo "----------------------------------------------------------"
  echo "Targetting Garden: ${1}"
  gardenctl target garden ${1}
}

function list_seeds() {
  gardenctl ls seeds | sed -e '/^seeds:/d' -e 's/- seed://g'
}

function target_seed() {
  echo ""
  echo "Targetting Seed: ${1}"
  gardenctl target seed ${1}
  echo ""
}

function list_shoots() {
  gardenctl ls shoots | egrep -v "project:|projects:|shoots:" | sed 's/  - //g'
}

function target_shoot() {
  echo "Targetting Shoot: ${1}"
  gardenctl target shoot ${1}
}

function fetch_aks_kubeconfig() {
  echo ""
  echo "Fetching kubeconfigs from AKS clusters"
  while read NAME GROUP
  do
    #rm ~/.kube/${NAME}-admin.config
    az aks get-credentials -g ${GROUP} -n ${NAME} --admin -f ~/.kube/${NAME}-admin.config
  done < <(az aks list -o tsv --query [].[name,resourceGroup])
}

function flatten_kubeconfig() {
  echo ""
  echo "Flattening kubeconfig files"
  KUBECONFIG=$(find ~/.kube ~/.garden \( -name "*.config" -o -name "kubeconfig.yaml" \) | tr "\n" ":" | sed 's/.$//') kubectl config view --flatten | sponge ~/.kube/config
}


fetch_aks_kubeconfig
for garden in $(list_gardens)
do
  target_garden ${garden}
  #target_seed $(list_seeds)
  #target_shoot $(list_shoots)
  for seed in $(list_seeds)
  do
    target_seed ${seed}
    for shoot in $(list_shoots)
    do
      target_shoot ${shoot}
    done
  done
done
echo "----------------------------------------------------------"
flatten_kubeconfig
