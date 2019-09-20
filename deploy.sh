#!/bin/bash
#=======================================================================================================================
# Script configuration
#
#   Version : 0.0.2
#   Author :  Sébastien Framinet
#
#   Ce script permet
#     - ajouter le hostname du projet au fichier /etc/hosts
#     - ajouter une configuration nginx
#     - télécharger les sources depuis git   (Optionnel)
#     - créer la base de donnée              (Optionnel)
#
# config :
#   - php                   : utilisation de la socket sur le port 9000 (php 7.2 par default chez asdoria)
#   - prestashop.conf.dist  : prestashop version 7.X
#   - symfony.conf.dist     : symfony 4.X
#   - wordpress.conf.dist   : wordpress
# =======================================================================================================================


#=================================================================
# Paramètre utilisateur
# ATTENTION : a changer selon le poste de l'utilistateur
#=================================================================
path_cmd=/usr/local/lib/deployLocal             #Path vers la lib deploy
default_project_path="$HOME/Workspace/site"     #Workspace de l'utilisateur
user="www-data"
group="www-data"
database_user="dev"                             #Utilisateur de la base de données
database_password="dev"                         #Password de la base de données
username="sframinet"                            #Utilisateur linux
#=================================================================


nginx_conf_path_available="/etc/nginx/sites-available"
nginx_conf_path_enable="/etc/nginx/sites-enabled"

#logfile=$path_cmd/logs/"`date "+%Y%m%d_%H%M%S"`.logs"
logfile=$path_cmd/logs/"`date "+%Y%m%d"`.logs"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

erreur()
{
    if (($? > 0)); then
        echo -e "${RED}Une erreur est survenue sur la commande précedente, lisez les logs : $logfile ${NC}"
        exit 100
    fi
}

clear
#=================================================
# Gestion des paramètres
#=================================================
#Nom du projet
echo -n "Nom du projet : "
read project_name
while [ -z $project_name ] ; do
     echo -n "Le nom de projet ne peut etre vide, Nom du projet : "
     read project_name
done

#Hostname
echo -n "Hostname [default : $project_name.local] : "
read hostname
if [ -z $hostname ] ; then
    hostname="$project_name.local"
fi

#Path
echo -n "Project Path [default : $default_project_path/$project_name] : "
read project_path
if [ -z $project_path ] ; then
    project_path="$default_project_path/$project_name"
fi

#Type de projet
echo -n "Type de projet : 0)Prestashop  1)Symfony  2)Wordpress : "
read project_type
while [ -z $project_type ] ; do
     echo -n "Mauvais type de projet, 0)Prestashop  1)Symfony  2)Wordpress :  "
     read project_type
done
while [ $project_type != 0 ] && [ $project_type != 1 ]  && [ $project_type != 2 ] ; do
     echo -n "Mauvais type de projet, 0)Prestashop  1)Symfony  2)Wordpress :  "
     read project_type
done
echo -e "\n"

#GIT
echo -n "Télécharger les sources depuis git Y,N ? [Default N] : "
read download_source
if [ -z $download_source ] ; then
    download_source="N"
fi
while [ $download_source != 'y' ] && [ $download_source != 'Y' ]  && [ $download_source != 'n' ] && [ $download_source != 'N' ] ; do
     echo -n "Mauvais paramètre, Télécharger les sources depuis gitlab Y,N ? [Default N] : "
     read download_source
done
if [ $download_source == 'y' ] || [ $download_source == 'Y' ] ; then
    echo -n "Url git des sources upstream (ex : git@gitlab.asdoria.org:alvis/alvis-audio.git) : "
    read url_git

    while [ -z $url_git ] ; do
         echo -n "Mauvais paramètre, Url git des sources (ex : git@gitlab.asdoria.org:alvis/alvis-audio.git) : "
         read url_git
    done
    # FORK
    echo -n "Avez-vous forké le projet Y,N ? [Default N] : "
    read fork
    if [ -z $fork ] ; then
        fork="N"
    fi
    while [ $fork != 'y' ] && [ $fork != 'Y' ]  && [ $fork != 'n' ] && [ $fork != 'N' ]
    do
         echo -n "Mauvais paramètre, Avez-vous forké le projet Y,N ? [Default N] : "
         read fork
    done
    if [ $fork == 'y' ] || [ $fork == 'Y' ] ; then
        echo -n "Url du fork : "
        read url_fork

        while [ -z $url_fork ]
        do
            echo -n "Mauvais paramètre, Url du fork :  "
            read url_fork
        done
    fi
fi
echo -e "\n"


#Base de donnée
echo -n "Créer une base de donnée Y,N ? [Default N] : "
read create_database
if [ -z $create_database ] ; then
    create_database="N"
fi
while [ $create_database != 'y' ] && [ $create_database != 'Y' ]  && [ $create_database != 'n' ] && [ $create_database != 'N' ] ; do
     echo -n "Mauvais paramètre, Créer une base de donnée Y,N ? [Default Y] : "
     read create_database
done

if [ $create_database == 'y' ] || [ $create_database == 'Y' ] ; then
    echo -n "Database name [default : $project_name)] : "
    read database_name
    if [ -z $database_name ] ; then
        database_name=$project_name
    fi
fi
echo -e "\n"

#=================================================
# Téléchargement des sources
#=================================================
if [ $download_source == 'y' ] || [ $download_source == 'Y' ] ; then
    echo "Téléchargement des sources via git : $url_git"
    #echo "sudo -u $username git clone $url_git $project_path"
    sudo -u $username git clone $url_git $project_path
    sudo -u $username git -C $project_path remote add upstream $url_git
    erreur
    if [ $fork == 'y' ] || [ $fork == 'Y' ] ; then
        sudo -u $username git -C $project_path remote set-url origin $url_fork
    fi
fi
echo -e "\n"

#=================================================
# Modification du fichier /etc/hosts
#=================================================
echo "127.0.0.1       $hostname" >> /etc/hosts

#=================================================
# Configuration NGINX
#=================================================

case $project_type in
        0)
                conf=$path_cmd/conf/prestashop.conf.dist
                ;;
        1)
                conf=$path_cmd/conf/symfony.conf.dist
                ;;
        2)
                conf=$path_cmd/conf/wordpress.conf.dist
                ;;
esac

full_path_conf="$nginx_conf_path_available/$project_name.conf"
echo "Création du fichier de configuration : $full_path_conf ...."
#echo "cp $conf $full_path_conf"
cp $conf $full_path_conf
erreur

#REMPLACEMENT DANS LE FICHIER DE CONF
sed -i "s+_PATH_+`echo $project_path`+g" $full_path_conf
sed -i "s+_HOSTNAME_+`echo $hostname`+g" $full_path_conf
echo "Fichier $full_path_conf créé"

echo "Création du lien symbolique : ln -s $full_path_conf $nginx_conf_path_enable"
ln -s $full_path_conf $nginx_conf_path_enable
echo -e "\n"

#=================================================
# Gestion des droits
#=================================================
chmod 775 -R $project_path/*
chown $user:$group -R $project_path/*

#=================================================
# Redemarrage du serveur
#=================================================
echo "Redemarrage du serveur nginx"
service nginx restart 2>> $logfile
erreur

#=================================================
# Création de la base de données
#=================================================

if [ $create_database == 'y' ] || [ $create_database == 'Y' ] ; then
    echo "Création de la base de donnée $database_name"
    create_database_sql="CREATE DATABASE $database_name CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    echo -n "mysql -u $database_user -p$database_password -e \"$create_database_sql\" "
    mysql -u $database_user -p$database_password -e "$create_database_sql" 2>> $logfile
    echo -e "\n"
fi

#=================================================
# Dump
#=================================================
if [ -d "$project_path/dump" ] ; then
    nbFiles=`ls "$project_path/dump/"*.sql | wc -l`
    if [ $nbFiles > 0 ] ; then
        echo  "Voulez-vous jouer un dump ? (n pour annuler)"
        echo -e "\n"
        files=( $project_path/dump/*.sql )

        PS3="Votre choix : "
        select file in "${files[@]}" ; do
            if [[ $REPLY == "n" ]] ; then
                exit
            elif [[ $REPLY == "N" ]]; then
                exit
            elif [[ -z $file ]]; then
                echo 'Invalid choice, try again' >&2
            else
                break
            fi
        done
       if [ ! -z $file ]
       then
            echo "Import du dump $file"
            echo "mysql -u $database_user -p$database_password -D "$database_name" < $file"
            mysql -u $database_user -p$database_password -D "$database_name" < $file
            echo -e "\n"
       fi
    fi

fi

echo -e "${GREEN}[SUCCESS]- lisez bien le README du projet - http://$hostname${NC}"