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
			echo "Erreur 8: La commande entrée n'existe pas";;
		9)
			echo "Erreur 9: L'utilisateur ou la machine que vous avez désigné pour envoyé votre message n'existe pas" > $(tty);;
	esac
}

function help {
	echo "help"
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
					if [[ "$password" == "$correct_password" ]] ; then 
						echo "Mot de passe correct" ;
						return 1;
					fi
				fi
			done < $fichier_user
			error 4
			return 0
	fi
}

# Fonction permettant de vérifier que le mot de passe administrateur est correct
function adminCheck {
    read -r -p "Entrez le mot de passe administrateur : " password
    admin_password=$(grep "admin" $fichier_user | cut -d ";" -f2)
    if [ "$password" == "$admin_password" ]; then
        return 1
    else
        error 4
        return 0
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
			appelCommande $command "$@"
		fi
		
	done
	
}


# Fonction permettant de changer les informations d'un utilisateur
function commande-afinger {
	# Demande comme argument : 
	#	1) le nom d'utilisateur dont l'utilisateur veut modifier les informations complémentaires
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi
	user="$1"
	echo "Informations de l'utilisateur $user"

	# On vérifie que l'utilisateur existe
	userCheck $user
	if [ $? -ne 1 ]; then
		return 0
	fi

	# On récupère les informations complémentaires de l'utilisateur et les affichent
	nom=$(grep "^$user;" $fichier_user | cut -d ";" -f 3)
	email=$(grep "^$user;" $fichier_user | cut -d ";" -f 4)
	echo "Nom : $nom"
	echo "Email : $email"

	# On demande à l'utilisateur de modifier les informations complémentaires
	# Le nom :
	read -p "Changer le prénom et nom de l'utilisateur $user ? (y/n) " reponse
	while [ $reponse != "y" ] && [ $reponse != "n" ]; do
		read -p "Changer le prénom et nom de l'utilisateur $user ? (y/n) " reponse
	done
	if [[ $reponse == "y" ]]; then
		read -p "Nouveau nom : " nom
	fi 
	# L'email
	read -p "Changer l'email de l'utilisateur $user ? (y/n) " reponse
	while [ $reponse != "y" ] && [ $reponse != "n" ]; do
		read -p "Changer l'email de l'utilisateur $user ? (y/n) " reponse
	done
	if [[ $reponse == "y" ]]; then
		read -p "Nouvel email : " email
	fi

	sed -i "s/^$user;\(.*\);.*;.*;\(.*\)$/$user;\1;$nom;$email;\2/" $fichier_user
}

# Fonction permettant de mettre à jour les connexions dans le fichier connexion
function updateConnexion {
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter
	#	2) le nom de la machine à laquelle il veut se connecter
	argCheck $# 2
	if [ $? -ne 1 ]; then
		return 0
	fi
	terminal=$(tty | sed 's/\//_/g')
	user="$1"
	machine="$2"

	machineCheck $machine
	if [ $? -ne 1 ]; then
		return 0
	fi

	text=$(grep "$terminal;$user;$machine" connexion | tail -1)
	
	date=$(dateToTimestamp)

	sed -i "s/$text/$terminal;$user;$machine;$date/" $fichier_machine

	return 1
}



# Fonction permettant à l'utilisateur de lancer une commande
function appelCommande {
	commande=$1
	shift
	if [ -z "$commande" ]; then
		echo ""
	else
		case $commande in
			"rconnect")
				commande-rconnect "$@";;
			"su")
				commande-su "$@";;
			"write")
				commande-write "$@";;
			"host")
				commande-host "$@";;
			"user")
				commande-user "$@";;
			"wall")
				commande-wall "$@";;
			"afinger")
				commande-afinger "$@";;
			*)
				echo "Commande inconnue";;
		esac
	fi
}


appelCommande $command "$@"