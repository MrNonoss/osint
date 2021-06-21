#!/bin/bash

#####################################
# Ce script est le lanceur d'outils #
# L'outil est choisi en fonction de #
# l'argument qui sera donné         #
#####################################

# Choix des outils
if [[ $1 == "a" ]]; then
  docker run --rm -v ghunt-resources:/usr/src/app/resources mxrch/ghunt ghunt.py email $2 | ansi2html | tee ~/osint/html/results/$2.html ~/osint/logs/recherches/ghunt_$2-$(date +"%Y-%m-%d_%T").html
elif [[ $1 == "b" ]]; then
  docker run --rm mrnonoss/holehe holehe --only-used $2 | ansi2html | tee ~/osint/html/results/$2.html ~/osint/logs/recherches/holehe_$2-$(date +"%Y-%m-%d_%T").html
elif [[ $1 == "c" ]]; then
  docker run --rm theyahya/sherlock --print-found  $2 | ansi2html | tee ~/osint/html/results/$2.html ~/osint/logs/recherches/sherlock_$2-$(date +"%Y-%m-%d_%T").html
elif [[ $1 == "d" ]]; then
  docker run --rm -v ~/osint/html/results:/Profil3r/reports/html mrnonoss/profil3r python3 profil3r.py -p $2 | tee ~/osint/logs/recherches/Profil3r_$2-$(date +"%Y-%m-%d_%T").html
elif [[ $1 == "e" ]]; then
  docker run --rm sundowndev/phoneinfoga scan -n $2 | ansi2html | tee ~/osint/html/results/$2.html ~/osint/logs/recherches/phoneinfoga_$2-$(date +"%Y-%m-%d_%T").html
else 
  echo 'Erreur'
  exit
fi
