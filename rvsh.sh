#!/bin/bash

# Variables permettant de configurer l'emplacement et nom des fichiers utilisés par ce script
chemin=$(pwd)
fichier_connexion=$chemin/connexion
fichier_machine=$chemin/machine
fichier_user=$chemin/user

source $chemin/commande_admin.sh
source $chemin/commande_connect.sh

if [[ "$1" == "-admin" || "$1" == "-connect" ]] ; then
	connexion "$@"
else
	error 1
fi

function error {
	case $1 in
		1) 
			echo "Erreur 1: Le nombre de paramètres entré n'est pas correct.";
			echo "Rappel:\n";
			echo "Mode connect : rvsh -connect <user_id> <machine_name>";
			echo "Mode admin : rvsh -admin <password_admin>";;
		2)
			echo "Erreur 2: Le nom de la machine entré n'existe pas";;
		3)
			echo "Erreur 3: Le nom de l'utilisateur entré n'existe pas";;
		4)	
			echo "Erreur 4: Le mot de passe entré est erroné";;
		5) 
			echo "Erreur 5: Vous n'avez pas accès à cette machine ou la machine que vous avez entré n'existe pas";;
		6) 
			echo "Erreur 6: Le mot de passe administrateur n'est pas correct";;
		7)
			echo "Erreur 7: L'option entrée n'existe pas";;
		8)
			echo "Erreur 8: La commande entrée n'existe pas";	
	esac
}

function help{
}

## Fonctions pour vérifier les informations entrées par l'utilisateur

# Fonction permettant de vérifier le nombre d'arguments
function argCheck { 
	# Demande comme argument :
	#	1) Le nombre d'arguments donné par l'utilisateur
	#	2) Le nombre d'arguments nécessaires à la fonction appelant argCheck
	if [ $1 -eq $2 ]; then
		return 1;
	else
		error 1
		return 0;
	fi
}

# Fonction permettant de vérifier qu'un utilisateur existe
function userCheck { 
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter
	echo "Vérification de l'existence de l'utilisateur"
	argCheck $# 1
	if [ $? -eq 1 ]; then
		user="$1"
		while read ligne
			do
				nom_user=$(echo $ligne | sed 's/^\(.*\);.*;.*;.*;.*$/\1/g');
				if [ $user == $nom_user ]; then 
					echo "Existence de l'utilisateur confirmée";
					return 1;
				fi
			done < $fichier_user
		error 3
		return 0
	fi
}

# Fonction permettant de vérifier qu'une machine existe
function machineCheck { 
	# Demande comme argument : 
	#	1) le nom de la machine à laquelle l'utilisateur veut se connecter
    echo "Vérification de l'existence de la machine"
	argCheck $# 1
	if [ $? -eq 1 ]; then
		machine="$1"
		while read ligne
			do
				nom_machine=$(echo $ligne | sed 's/^.*;\(.*\);.*$/\1/g');
				if [ $machine == $nom_machine ]; then 
					echo "Existence de la machine confirmée";
					return 1;
				fi
			done < $fichier_machine
		error 3
		return 0
	fi
}

# Fonction permettant de vérifier que l'utilisateur a les droits d'accès à la machine
function accessCheck {
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter, 
	#	2) le nom de la machine à laquelle il veut se connecter
	echo "Vérification des accès de l'utilisateur à la machine"
	argCheck $# 2
	if [ $? -eq 1 ]; then
		user="$1"
		machine="$2"
		while read ligne
			do
                echo "$ligne"
				if [ $machine == $(echo $ligne | sed 's/^.*;\(.*\);.*$/\1/g') ]; then # On trouve la machine dans le fichier 
                    echo "trouvé"
					access=$(echo $ligne | sed 's/^.*;\(.*\)$/\1/g' | sed "s/^.*,$user,.*$/,$user,/g") ; # On récupère sa liste d'accès et on essaie d'y trouver le nom d'utilisateur avec lequel l'utilisateur veut accéder à la machine
					if [ ",$user," == $access ]; then 
						echo "Accès authorisé à $machine" ;
						return 1;
					fi
				fi
			done < $fichier_machine
			error 5
			return 0;
	fi
}

# Fonction permettant de vérifier que le mot de passe entré est correct
function passwordCheck {
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter
	argCheck $# 1
	if [ $? == 1 ]; then
		user="$1"
		read -sp "Entrez le mot de passe de $user : " password
		while read ligne
			do
                nom_user=$(echo $ligne | sed 's/^\(.*\);.*;.*;.*;.*$/\1/g')
				if [ $user == $nom_user ] ; then # On trouve le user dans le fichier 
					correct_password=$(echo $ligne | sed 's/^.*;\(.*\);.*;.*;.*$/\1/g') ; # On récupère le mot de passe correct
					if [ "$password" == "$correct_password" ] ; then 
						echo "Mot de passe correct" ;
						return 1;
					fi
				fi
			done < $fichier_user
			error 4
			return 0;
	fi
}

# Fonction premettant de convertir la date en timestamp
function dateToTimestamp {
	date=$(date)
	year=$(echo $date | cut -d " " -f 6)
	month=$(echo $date | cut -d " " -f 2)
	day=$(echo $date | cut -d " " -f 3)
	hour=$(echo $date | cut -d " " -f 4 | cut -d ":" -f 1)
	minute=$(echo $date | cut -d " " -f 4 | cut -d ":" -f 2)
	seconde=$(echo $date | cut -d " " -f 4 | cut -d ":" -f 3)
	
	case $month in
		Jan)
			month=01;;
		Feb)
			month=02;;
		Mar)
			month=03;;
		Apr)
			month=04;;
		May)
			month=05;;
		Jun)
			month=06;;
		Jul)
			month=07;;
		Aug)
			month=08;;
		Sep)
			month=09;;
		Oct)
			month=10;;
		Nov)
			month=11;;
		Dec)
			month=12;;
	esac
	
	echo "$year$month$day$hour$minute$seconde"
}

# Fonction permettant d'ajouter une connexion dans le fichier de connexion
function addConnexion {
	argCheck $# 2
	if [ $? -ne 1 ]; then
		return 0
	fi

	terminal=$(tty | sed 's/\//_/g')
	user=$1
	machine=$2
	date=$(dateToTimestamp)

	echo "$terminal;$user;$machine;$date" >> connexion
	
}

# Fonction permettant de supprimer une connexion dans le fichier de connexion
function removeConnexion {
	argCheck $# 2
	if [ $? -ne 1 ]; then
		error 1
		return 0
	fi

	terminal=$(tty | sed 's/\//_/g')
	user=$1
	machine=$2

	text=$(grep "$terminal;$user;$machine" connexion | tail -1)
	sed -i "/$text/d" connexion
}


function connexion {
	# Demande comme argument : 
	#	1) la commande -connect ou -admin
	#	2) le nom d'utilisateur avec lequel l'utilisateur veut se connecter, 
	#	3) le nom de la machine à laquelle il veut se connecter
	if [[ $1 == "-admin" ]] ; then
		argCheck $# 1
		if [[ $? -eq 1 ]] ; then
			$user="admin"
			$machine="hostroot"
		else
			return 0
		fi
	else
		argCheck $# 3
		if [[ $? -eq 1 ]] ; then
			$user="$2"
			$machine="$3"
		else
			return 0
		fi
	fi

	# On vérifie que l'utilisateur existe
	userCheck $user
	if [[ $? -ne 1 ]] ; then
		return 0
	fi

	# On vérifie que le mot de passe est correct
	passwordCheck $user
	if [[ $? -ne 1 ]] ; then
		return 0
	fi
	
	# On vérifie que la machine existe
	machineCheck $machine
	if [[ $? -eq 1 ]] ; then
		return 0
	fi

	# On vérifie que l'utilisateur a le droit d'accéder à la machine
	accessCheck $user $machine
	if [[ $? -ne 1 ]] ; then
		return 0
	fi

	# On ajoute la connexion dans le fichier de connexion
	addConnexion $user $machine

	# On piège toutes les sorties de la commande, afin de pouvoir procéder au logout
	trap logout EXIT

	# On lance la boucle de commande, qui permettra à l'utilisateur de rentrer des commandes
	while true; do
		read -p "$user@$machine> " commande

		if [[ $commande == "exit" ]] ; then
			logout
		else
			appelCommande $command "$@"
		fi
		
	done
	
}

function appelCommande {
	commande=$1
	shift 
	if [ "$(type -t $commande)" = "function" ]; then
		"commande-$commande" "$@"
	elif [ -z "$commande" ]; then
		echo
	else
		commandeInconnue $commande
	fi
}

function commandeInconnue {
	echo "Commande inconnue : $1"
}

function logout {
	echo "Déconnexion de $user@$machine"
	removeConnexion $user $machine $(tty)
	exit 0
}

# Fonction permettant de constituer une liste des utilisateurs ayant les accès à une machine
function viewAccessMachine {
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi

	machine=$1
	access=$(grep "$machine" machine | cut -d ";" -f2 | sed 's/,/ /g')
	echo "Utilisateur ayant accès à la machine $machine :$access"
}

# Fonction permettant d'ajouter un membre à la liste des utilisateurs ayant les accès à une machine
function addAccessMachine {
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi

	machine=$1
	viewAccessMachine $machine


	read -p "Ajouter un utilisateur à la liste des utilisateurs ayant accès à cette machine ? (y/n) " reponse
	while [ $reponse != "y" ] && [ $reponse != "n" ]; do
		read -p "Ajouter un utilisateur à la liste des utilisateurs ayant accès à cette machine ? (y/n) " reponse
	done
	while [ $reponse == "y" ]; do
		read -p "Entrer le nom de l'utilisateur à ajouter à cette liste : " user

		userCheck $user
		if [[ $? -ne 1 ]] ; then
			return 0
		fi

		oldAccess=$(grep "$machine" machine | cut -d ";" -f2)
		newAccess="$oldAccess$user,"
		sed -i "s/$machine;$oldAccess/$machine;$newAccess/" machine

		read -p "Ajouter un autre utilisateur à la liste des utilisateurs ayant accès à cette machine ? (y/n) " reponse
		while [ $reponse != "y" ] && [ $reponse != "n" ]; do
			read -p "Ajouter un autre utilisateur à la liste des utilisateurs ayant accès à cette machine ? (y/n) " reponse
		done
	done
}

# Fonction permettant d'ajouter un membre à la liste des utilisateurs ayant les accès à une machine
function removeAccessMachine {
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi

	machine=$1
	viewAccessMachine $machine


	read -p "Supprimer un utilisateur de la liste des utilisateurs ayant accès à cette machine ? (y/n) " reponse
	while [ $reponse != "y" ] && [ $reponse != "n" ]; do
		read -p "Supprimer un utilisateur de la liste des utilisateurs ayant accès à cette machine ? (y/n) " reponse
	done
	while [ $reponse == "y" ]; do
		read -p "Entrer le nom de l'utilisateur à supprimer de cette liste : " user

		accessCheck $user $machine
		if [[ $? -ne 1 ]] ; then
			return 0
		fi

		oldAccess=$(grep "$machine" machine | cut -d ";" -f2)
		newAccess=$(echo $oldAccess | sed "s/$user,//g")
		sed -i "s/$machine;$oldAccess/$machine;$newAccess/" machine

		read -p "Supprimer un autre utilisateur de la liste des utilisateurs ayant accès à cette machine ? (y/n) " reponse
		while [ $reponse != "y" ] && [ $reponse != "n" ]; do
			read -p "Supprimer un autre utilisateur de la liste des utilisateurs ayant accès à cette machine ? (y/n) " reponse
		done
	done
}



# Fonction permettant d'ajouter une machine dans le fichier machine
function addMachine {
	argCheck $# 0
	if [ $? -ne 1 ]; then
		return 0
	fi

	read -p "Nom de la machine : " machine
	echo "$machine;,admin," >> machine

	access=$(addAccess $machine)
	
}

# Fonction permettant de supprimer une machine dans le fichier connexion
function removeMachine {
	argCheck $# 0
	if [ $? -ne 1 ]; then
		error 1
		return 0
	fi

	read -p "Nom de la machine : " machine

	machineCheck $machine
		if [[ $? -ne 1 ]] ; then
			return 0
		fi

	sed -i "/$machine/d" machine
}