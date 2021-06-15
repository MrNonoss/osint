#!/bin/bash

clear
echo "Ce script va:
1 - Vérifier la présence de docker et docker-compose
2 - Mettre a jour le fuseau horaire
3 - Télécharger les images docker utiles (ce qui risque prendre du temps)
4 - Créer un tube nommé (docker run --rm -v ghunt-resources:/usr/src/app/resources --name ghunt -ti mxrch/ghunt check_and_gen.py)
5 - Créer un service au démarrage pour mettre le tube nommé en écoute
6 - Paramétrage de la rotation des logs
7 - Ajouter une tache cron pour vider les résultats
8 - Créer un wrapper d'application dans /usr/local/bin/
9 - Lancer un docker-compose pour le serveur web
10 - Paramétrer les cookies pour Ghunt (https://github.com/mxrch/GHunt#where-i-find-these-5-cookies-)"
echo ""
read -p "Appuyez sur Entrée pour continuer"

# Vérification des prérequis #
echo "
# Vérification des prérequis #"
if [ `whoami` != root ]; then
    echo "Le script doit être lancé en sudoer"
    exit
fi

if ! [ -x "$(command -v docker)" ]; then
  echo 'Erreur: Faut installer docker.' >&2
  exit 1
elif ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Erreur: Faut installer docker-compose.' >&2
  exit 1 
fi

# Mise a jour du fuseau horaire #
echo "
# Mise a jour du fuseau horaire #"
timedatectl set-timezone Europe/Paris

# Téléchargement des images Docker #
echo "
# Téléchargement des images Docker #"
docker pull mxrch/ghunt
docker pull sundowndev/phoneinfoga
docker pull theyahya/sherlock
docker pull mrnonoss/holehe
docker pull mrnonoss/profil3r

# Création du tube nommé (named pipe)           #
# https://stackoverflow.com/a/63719458/13295495 #
echo "
# Création du tube nommé (named pipe) #"
mkfifo html/scripts/pipe

# Mise en écoute des tubes nommés #
echo "
# Mise en écoute des tubes nommés #"
echo "[Unit]
Description=Mise en écoute du tube nommé

[Service]
ExecStart=html/scripts/pipe.sh start

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/pipe.service
chmod 644 /lib/systemd/system/pipe.service
ln -s /lib/systemd/system/pipe.service /etc/systemd/system/pipe.service
systemctl enable pipe

# Paramétrage de la rotation des logs #
echo "
# Paramétrage de la rotation des logs #"
echo "~/osint/logs/access.log {
        rotate 52
        weekly
        compress
        delaycompress
        dateext
        notifempty
        missingok
}" > /etc/logrotate.d/caddy
chmod 644 /etc/logrotate.d/caddy

# Ajout de la tache cron pour vider les résultats #
echo "
# Ajout de la tache cron pour vider les résultats #"
crontab -l | { cat; echo "0 * * * * rm -Rf ~/osint/html/results/* >/dev/null 2>&1"; } | crontab -

# Copie du wrapper d'applications #
echo "
# Copie du wrapper d'applications #"
mv html/scripts/tools.sh /usr/local/bin/

# Lancement du docker-compose #
echo "
# Lancement du docker-compose #"
docker-compose up -d

# Création des cookies Ghunt #
echo "
# Création des cookies Ghunt #"
docker run --rm -ti -v ghunt-resources:/usr/src/app/resources --name ghunt -ti mxrch/ghunt check_and_gen.py