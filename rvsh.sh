#!/bin/bash

# Variables permettant de configurer l'emplacement et nom des fichiers utilisés par ce script
fichier_connexion=./connexion
fichier_machine=./machine
fichier_user=./user


function error{
	case $1 in
		1) 
			echo"Erreur 1: Le nombre de paramètres entré n'est pas correct.";
			echo"Rappel:\n";
			echo"Mode connect : rvsh -connect <user_id> <machine_name>";
			echo"Mode admin : rvsh -admin <password_admin>";;
		2)
			echo"Erreur 2: Le nom de la machine entré n'existe pas";;
		3)
			echo"Erreur 3: Le nom de l'utilisateur entré n'existe pas";;
		4)	
			echo"Erreur 4: Le mot de passe entré est erroné";;
		5) 
			echo"Erreur 5: Vous n'avez pas accès à cette machine ou la machine que vous avez entré n'existe pas";;
		6) 
			echo"Erreur 6: Le mot de passe administrateur n'est pas correct";;
		7)
			echo"Erreur 7: L'option entrée n'existe pas";;
		8)
			echo"Erreur 8: La commande entrée n'existe pas";	
	esac
}

function help{
}

function argCheck{ # Fonction permettant 
	# Demande comme argument :
	#	1) Le nombre d'arguments donné par l'utilisateur
	#	2) Le nombre d'arguments nécessaires à la fonction appelant argCheck
	if [ $1 -eq $2 ]; then
		return 1;
	else
		error () 1
		return 0;
	fi
}

function userCheck{ # Fonction permettant de vérifier qu'un utilisateur existe
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter
	echo "Vérification de l'existence de l'utilisateur"
	argCheck() $# 1
	if [ $? -eq 1 ]; then

		while read ligne
			do
				nom_user=$(echo $ligne | sed 's/^\(.*\);.*;.*;.*$/\1/g');
				if [ $1 -eq $nom_user ]; then 
					echo "Existence de l'utilisateur confirmée";
					return 1;
				fi
			done < $fichier_user
		error() 3
		return 0
	fi
}

function accessCheck{
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter, 
	#	2) le nom de la machine à laquelle il veut se connecter
	echo "Vérification des accès de l'utilisateur à la machine"
	argCheck() $# 2
	if [ $? -eq 1 ]; then
		while read ligne
			do
				if [ $1 -eq $(echo $ligne | sed 's/^\(.*\);.*$/\1/g') ]; then # On trouve la machine dans le fichier 
					access=$(echo $ligne | sed 's/^.*;\(.*\)$/\1/g' | sed "s/^.*,$1,.*$/,$1,/g") ; # On récupère sa liste d'accès et on essaie d'y trouver le nom d'utilisateur avec lequel l'utilisateur veut accéder à la machine
					if [ $1 -eq $access ]; then 
						echo "Accès authorisé à $2" ;
						return 1;
					fi
				fi
			done < $fichier_machine
			error() 2
			return 0;
	fi
}

function passwordCheck{
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter
	argCheck() $# 1
	if [ $? -eq 1 ]; then
		read -sp "Entrez le mot de passe de $1" password
		while read ligne
			do
				if [ $2 -eq $(echo $ligne | sed 's/^\(.*\);.*;.*;.*$/\1/g') ]; then # On trouve le user dans le fichier 
					correct_password=$(echo $ligne | 's/^.*;\(.*\);.*;.*$/\1/g') ; # On récupère le mot de passe correct
					if [ $1 -eq $correct_password ]; then 
						echo "Mot de passe correct" ;
						return 1;
					fi
				fi
			done < $fichier_user
			error() 2
			return 0;
	fi
}

function addConnexion{
	argCheck() $# 1
	if [ $? -eq 1 ]; then
	fi
}

function removeConnexion{
	argCheck() $# 1
	if [ $? -eq 1 ]; then
	fi
}

function -connect{
	argCheck() $# 2
	if [ $? -eq 1 ]; then
		userCheck() $1
		if [ $? -eq 1 ]; then
			userCheck() $1
		
		fi
	fi
}


