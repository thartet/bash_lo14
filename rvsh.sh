#!/bin/bash

# Variables permettant de configurer l'emplacement et nom des fichiers utilisés par ce script
chemin=$(pwd)
fichier_connexion=$chemin/connexion
fichier_machine=$chemin/machine
fichier_user=$chemin/user

source $chemin/commande_admin.sh
source $chemin/commande_connect.sh


function error {
	case $1 in
		1) 
			echo "Erreur 1: Le nombre de paramètres entré n'est pas correct." > $(tty);
			echo "Rappel:" > $(tty);
			echo "Mode connect : rvsh -connect <user_id> <machine_name>" > $(tty);
			echo "Mode admin : rvsh -admin <password_admin>";;
		2)
			echo "Erreur 2: Le nom de la machine entré n'existe pas" > $(tty);;
		3)
			echo "Erreur 3: Le nom de l'utilisateur entré n'existe pas" > $(tty);;
		4)	
			echo "Erreur 4: Le mot de passe entré est erroné" > $(tty);;
		5) 
			echo "Erreur 5: Vous n'avez pas accès à cette machine ou la machine que vous avez entré n'existe pas" > $(tty);;
		6) 
			echo "Erreur 6: Le mot de passe administrateur n'est pas correct" > $(tty);;
		7)
			echo "Erreur 7: L'option entrée n'existe pas" > $(tty);;
		8)
			echo "Erreur 8: La commande entrée n'existe pas" > $(tty);;
		9)
			echo "Erreur 9: L'utilisateur ou la machine que vous avez désigné pour envoyé votre message n'existe pas" > $(tty);;
	esac
}


function help {
	echo ""
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
		user=$1
		while read ligne
			do
				nom_user=$(echo $ligne | sed 's/^\(.*\);.*;.*;.*;.*$/\1/g');
				if [ $user == $nom_user ]; then 
					echo "Existence de l'utilisateur confirmée"
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
				nom_machine=$(echo $ligne | sed 's/^\(.*\);.*$/\1/g');
				if [ $machine == $nom_machine ]; then 
					echo "Existence de la machine confirmée"
					return 1;
				fi
			done < $fichier_machine
		error 2
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
				if [ $machine == $(echo $ligne | sed 's/^\(.*\);.*$/\1/g') ]; then # On trouve la machine dans le fichier machine
					access=$(echo $ligne | sed 's/^.*;\(.*\)$/\1/g' | sed "s/^.*,$user,.*$/,$user,/g") ; # On récupère sa liste d'accès et on essaie d'y trouver le nom d'utilisateur avec lequel l'utilisateur veut accéder à la machine
					if [ ",$user," == $access ]; then 
						echo "Accès authorisé à $machine" > "$(tty)"
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
						echo "Mot de passe correct"
						return 1;
					fi
				fi
			done < $fichier_user
			error 4
			return 0;
	fi
}


# Fonction permettant de vérifier que l'utilisateur est connecté à la machine
function connectedCheck {
	# Demande comme argument :
	#	1) le nom de l'utilisateur
	#	2) le nom de la machine
	user=$1
	machine=$2

	# On vérifie que l'utilisateur est connecté à la machine
	if [[ $(grep "$user;$machine" $fichier_connexion) == "" ]] ; then
		error 9
		return 0
	else
		return 1
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
	
    if [ $day -lt 10 ]; then
        day=$(echo "0$day")
    fi

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
	# Demande comme argument : 
	#	1) le nom d'utilisateur de la connexion à ajouter
	#	2) le nom de la machine de la connexion à ajouter
	argCheck $# 2
	if [ $? -ne 1 ]; then
		return 0
	fi

	terminal=$(tty | sed 's/\//_/g')
	user=$1
	machine=$2
	date=$(dateToTimestamp)

	echo "$terminal;$user;$machine;$date" >> $fichier_connexion
	
}


# Fonction permettant de supprimer une connexion dans le fichier de connexion
function removeConnexion {
	# Demande comme argument : 
	#	1) le nom d'utilisateur de la connexion à supprimer
	#	2) le nom de la machine de la connexion à supprimer
	argCheck $# 2
	if [ $? -ne 1 ]; then
		error 1
		return 0
	fi

	terminal=$(tty | sed 's/\//_/g')
	user=$1
	machine=$2

	text=$(grep "$terminal;$user;$machine" $fichier_connexion | tail -1)
	sed -i "/$text/d" $fichier_connexion
}


# Fonction permettant de mettre à jour les connexions dans le fichier connexion
function updateConnexion {
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur va exécuter une commande
	#	2) le nom de la machine avec laquelle il veut exécuter une commande
	argCheck $# 2
	if [ $? -ne 1 ]; then
		return 0
	fi
	terminal=$(tty | sed 's/\//_/g')
	user="$1"
	machine="$2"
	date=$(dateToTimestamp)


	machineCheck $machine
	if [ $? -ne 1 ]; then
		return 1
	fi

	text=$(grep "$terminal;$user;$machine" connexion | tail -1)
	
	date=$(dateToTimestamp)

	sed -i "s/$text/$terminal;$user;$machine;$date/" $fichier_connexion

	return 2
}


function connexion {
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter, 
	#	2) le nom de la machine à laquelle il veut se connecter
	user=$1
	machine=$2

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
	if [[ $? -ne 1 ]] ; then
		return 0
	fi

	# On vérifie que l'utilisateur a le droit d'accéder à la machine
	accessCheck $user $machine
	if [[ $? -ne 1 ]] ; then
		return 0
	fi

	# On ajoute la connexion dans le fichier de connexion
	addConnexion $user $machine

	# On affiche les message sauvegardé pendant que l'utilisateur était déconnecté
	readSavedMessage $user

	# On lance la boucle de commande, qui permettra à l'utilisateur de rentrer des commandes
	while true; do
		read -p "$user@$machine> " commande

		if [[ $commande == "exit" ]] ; then
			new=$(logout 1 $user $machine)
			if [[ $new == "Sorti" ]] ; then
				break
			else
				user=$(echo $new | cut -d ";" -f 1)
				machine=$(echo $new | cut -d ";" -f 2)
			fi
		else
			updateConnexion $user $machine
			if [ $? -eq 1 ]; then
				new=$(logout 1 $user $machine)
				if [[ $new == "Sorti" ]] ; then
					break
				else
					user=$(echo $new | cut -d ";" -f 1)
					machine=$(echo $new | cut -d ";" -f 2)
				fi
			fi
			appelCommande $commande
		fi
		
	done
	
}


# Fonction permettant à l'utilisateur de lancer une commande
function appelCommande {
	commande=$1
	shift
	if [ -z "$commande" ]; then
		echo ""
	else
		case $commande in
			rconnect)
				commande-rconnect "$@";;
			su)
				commande-su "$@";;
			write)
				commande-write "$@";;
			host)
				commande-host "$@";;
			user)
				commande-user "$@";;
			who)
				commande-who "$@";;
			rusers)
				commande-rusers "$@";;
			rhost)
				commande-rhost "$@";;
			finger)
				commande-finger "$@";;
			passwd)
				commande-passwd "$@";;	
			wall)
				commande-wall "$@";;
			afinger)
				commande-afinger "$@";;
		esac
	fi
}


function commandeInconnue {
	echo "Commande inconnue : $1" > $(tty)
}


# Fonction permettant de déconnecter l'utilisateur
function logout {
	option=$1
	user=$2
	machine=$3

	echo "Déconnexion de $user@$machine" > $(tty)

	if [[ $option -eq 1 ]] ; then
		removeConnexion $user $machine
		if [[ -z $(grep "$(tty | sed 's/\//_/g');" $fichier_connexion) ]] ; then
			echo "Vous allez être déconnecté du réseau de machine virtuelle." > $(tty)
			echo "Sorti"
		else 
			newUser=$(grep "$terminal;" $fichier_connexion | tail -1 | cut -d ";" -f 2)
			newMachine=$(grep "$terminal;" $fichier_connexion | tail -1 | cut -d ";" -f 3)
			echo "$newUser;$newMachine"
		fi
	elif [[ $option -eq 2 ]] ; then
		if [[ -z $(grep "$(tty | sed 's/\//_/g');" $fichier_connexion) ]] ; then
			echo "Vous allez être déconnecté du réseau de machine virtuelle." > $(tty)
			echo "Sorti"
		else 
			newUser=$(grep "$terminal;" $fichier_connexion | tail -1 | cut -d ";" -f 2)
			newMachine=$(grep "$terminal;" $fichier_connexion | tail -1 | cut -d ";" -f 3)

			if [[ $newMachine != $machine ]] ; then
				echo "La machine $machine n'existe pas. Vous allez être déconnecté." > $(tty)
			elif [[ $newUser != $user ]] ; then
				echo "L'utilisateur $user n'existe pas. Vous allez être déconnecté." > $(tty)
			fi

			echo "$newUser;$newMachine"
		fi
	fi

}



if [[ $1 == "-admin" ]] ; then
	argCheck $# 1
	if [[ $? -eq 1 ]] ; then
		user="admin"
		machine="hostroot"
		connexion $user $machine
	fi
elif [[ "$1" == "-connect" ]] ; then
	argCheck $# 3
	if [[ $? -eq 1 ]] ; then
		user="$2"
		machine="$3"
		connexion $user $machine
	fi
else
	error 1
fi