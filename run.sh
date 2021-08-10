#!/bin/bash

clear
echo "Ce script va:
1 - Vérifier la présence de docker et docker-compose
2 - Mettre à jour le fuseau horaire du serveur
3 - Télécharger les images docker utiles (ce qui risque prendre du temps)
4 - Créer des scripts (wrapper d'application et écoute du tube nommé)
5 - Créer un tube nommé (https://stackoverflow.com/a/63719458/13295495)
6 - Créer un service au démarrage pour mettre le tube nommé en écoute
7 - Paramétrer la rotation des logs
8 - Ajouter une tache cron pour sauvegarder les requêtes
9 - Ajouter une tache cron pour vider les résultats
10 - Lancer un docker-compose pour le serveur web
11 - Paramétrer les cookies pour Ghunt (https://github.com/mxrch/GHunt#where-i-find-these-5-cookies-)"
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
fi

if ! [[ -x "$(command -v docker-compose)" ]]; then
  echo 'Erreur: Faut installer docker-compose.' >&2
  exit 1 
fi

if ! [[ -x "$(command -v ansi2html)" ]]; then
  echo 'Erreur: Faut installer colorized-logs.' >&2
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
mkdir html/pipe html/results logs logs/resultats
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

# Création du wrapper d'application #
echo "
# Création du wrapper d'application"
echo "#!/bin/sh
if [[ \$1 == "a" ]]; then
  docker run --rm -v ghunt-resources:/usr/src/app/resources mxrch/ghunt ghunt.py email \$2 | ansi2html | tee $PWD/html/results/\$2.html $PWD/logs/recherches/ghunt_\$2-$(date +"%Y-%m-%d_%T").html
elif [[ \$1 == "b" ]]; then
  docker run --rm mrnonoss/holehe holehe --only-used \$2 | ansi2html | tee $PWD/html/results/\$2.html $PWD/logs/recherches/holehe_\$2-$(date +"%Y-%m-%d_%T").html
elif [[ \$1 == "c" ]]; then
  docker run --rm theyahya/sherlock --print-found  \$2 | ansi2html | tee $PWD/html/results/\$2.html $PWD/logs/recherches/sherlock_\$2-$(date +"%Y-%m-%d_%T").html
elif [[ \$1 == "d" ]]; then
  docker run --rm -v $PWD/html/results:/Profil3r/reports/html mrnonoss/profil3r python3 profil3r.py -p \$2 | tee $PWD/logs/recherches/Profil3r_\$2-$(date +"%Y-%m-%d_%T").html
elif [[ \$1 == "e" ]]; then
  docker run --rm sundowndev/phoneinfoga scan -n \$2 | ansi2html | tee $PWD/html/results/\$2.html $PWD/logs/recherches/phoneinfoga_\$2-$(date +"%Y-%m-%d_%T").html
else 
  echo 'Erreur'
  exit
fi" > /usr/local/bin/tools.sh
chmod +x scripts/tools.sh

# Création du script d'écoute #
echo "
# Création du script d'écoute "
echo "#!/bin/sh
while true; do eval "$(cat $PWD/html/pipe/pipe)"; done" > /usr/local/bin/pipe.sh
chmod +x /usr/local/bin/pipe.sh

# Création du tube nommé (named pipe)           #
# https://stackoverflow.com/a/63719458/13295495 #
echo "
# Création du tube nommé (named pipe)"
mkfifo html/pipe/pipe -m755

# Création du service d'écoute des tubes nommés #
echo "
# Création du service d'écoute des tubes nommés"
echo "[Unit]
Description=Mise en écoute du tube nommé

[Service]
ExecStart=pipe.sh start

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/pipe.service
chmod 644 /lib/systemd/system/pipe.service
ln -s /lib/systemd/system/pipe.service /etc/systemd/system/pipe.service
systemctl enable pipe
systemctl start pipe

# Paramétrage de la rotation des logs #
echo "
# Paramétrage de la rotation des logs"
echo "$PWD/logs/access.log {
        rotate 52
        weekly
        compress
        delaycompress
        dateext
        notifempty
        missingok
}" > /etc/logrotate.d/caddy
chmod 644 /etc/logrotate.d/caddy

# Ajout de la tache cron pour sauvegarder les requêtes #
echo "
# Ajout de la tache cron pour sauvegarder les requêtes"
crontab -u $user -l | { cat; echo "* * */10 * * tar --create --gzip --file=$PWD/logs/resultats-$(date +%-Y%-m%-d)-$(date +%-T).tgz $PWD/logs/resultats/ >/dev/null 2>&1 && rm $PWD/logs/resultats/*"; } | crontab -

# Ajout de la tache cron pour vider les résultats #
echo "
# Ajout de la tache cron pour vider les résultats à minuit"
crontab -u $user -l | { cat; echo "0 * * * * rm -Rf $PWD/html/results/* >/dev/null 2>&1"; } | crontab -

# Lancement du docker-compose #
echo "
# Lancement du docker-compose"
docker-compose up -d

# Création des cookies Ghunt #
echo "
# Création des cookies Ghunt"
docker run --rm -ti -v ghunt-resources:/usr/src/app/resources --name ghunt -ti mxrch/ghunt check_and_gen.py