#!/bin/bash

clear
echo "Ce script va:
1 - Vérifier la présence de docker et docker-compose
2 - Mettre a jour le fuseau horaire
3 - Télécharger les images docker utiles (ce qui risque prendre du temps)
4 - Copie des scripts dans /usr/local/bin/
5 - Créer un tube nommé (https://stackoverflow.com/a/63719458/13295495)
6 - Créer un service au démarrage pour mettre le tube nommé en écoute
7 - Paramétrage de la rotation des logs
8 - Ajouter une tache cron pour vider les résultats
9 - Lancer un docker-compose pour le serveur web
10 - Paramétrer les cookies pour Ghunt (https://github.com/mxrch/GHunt#where-i-find-these-5-cookies-)"
echo ""
read -p "Appuyez sur Entrée pour continuer"

# Vérification des prérequis #
echo "
# Vérification des prérequis"
if [[ `whoami` != root ]]; then
    echo "Le script doit être lancé en sudoer"
    exit
fi

if ! [[ -x "$(command -v docker)" ]]; then
  echo 'Erreur: Faut installer docker.' >&2
  apt update && apt install docker -y
fi

if ! [[ -x "$(command -v docker-compose)" ]]; then
  echo 'Erreur: Faut installer docker-compose.' >&2
  apt update && apt install docker-compose -y
  exit 1 
fi

if ! [[ -x "$(command -v ansi2html)" ]]; then
  echo 'Erreur: Faut installer colorized-logs.' >&2
  apt update && apt install colorized-logs -y
  exit 1 
fi

# Vérification de l'utilisateur
user_check() {
  user=$(grep "1000:1000" /etc/passwd | cut -d ":" -f1)
  read -p "\"$user\" est-il bien votre utilisateur? [O/n] " -n 1 -r nom
  if [[ $nom =~ ^[Nn]$ ]] ; then
    echo ""
    read -p "Alors quel est-il? " user
    verif=$(cut -d ":" -f1 /etc/passwd | grep $user)
      if [[ -z "$verif" ]]; then
	    echo "Cet utilisateur n'existe pas. Interruption"
	    exit
	  fi
    echo "Ok, $user est enregistré"
  elif [[ ! $nom =~ ^[Oo]$ ]] ; then
  echo ""
    echo "Il faut choisir \"Oui\" ou \"Non\""
	user_check
  fi
}
user_check

# Correction des droits utilisateurs
mkdir html/pipe html/results logs/resultats
sudo chown -R $user:$user .

# Mise a jour du fuseau horaire #
echo "
# Mise a jour du fuseau horaire"
timedatectl set-timezone Europe/Paris

# Téléchargement des images Docker #
echo "
# Téléchargement des images Docker"
docker pull mxrch/ghunt
docker pull sundowndev/phoneinfoga
docker pull theyahya/sherlock
docker pull mrnonoss/holehe
docker pull mrnonoss/profil3r
docker pull caddy
docker pull mrnonoss/php8.0.5-pdo-pgsql
docker pull containrrr/watchtower

# Copie des scripts #
echo "
# Copie des scripts"
chmod +x scripts/tools.sh scripts/pipe.sh
sudo mv scripts/tools.sh /usr/local/bin/
sudo mv scripts/pipe.sh /usr/local/bin/

# Création du tube nommé (named pipe)           #
# https://stackoverflow.com/a/63719458/13295495 #
echo "
# Création du tube nommé (named pipe) et du répertoire de résultats"
mkfifo html/pipe/pipe -m755

# Mise en écoute des tubes nommés #
echo "
# Mise en écoute des tubes nommés"
echo "[Unit]
Description=Mise en écoute du tube nommé

[Service]
ExecStart=pipe.sh start

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/pipe.service
chmod 644 /lib/systemd/system/pipe.service
ln -s /lib/systemd/system/pipe.service /etc/systemd/system/pipe.service
systemctl enable pipe

# Paramétrage de la rotation des logs #
echo "
# Paramétrage de la rotation des logs"
echo "$HOME/osint/logs/access.log {
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
# Ajout de la tache cron pour vider les résultats"
crontab -u $user -l | { cat; echo "0 * * * * rm -Rf $HOME/osint/html/results/* >/dev/null 2>&1"; } | crontab -

# Lancement du docker-compose #
echo "
# Lancement du docker-compose"
docker-compose up -d

# Création des cookies Ghunt #
echo "
# Création des cookies Ghunt"
docker run --rm -ti -v ghunt-resources:/usr/src/app/resources --name ghunt -ti mxrch/ghunt check_and_gen.py