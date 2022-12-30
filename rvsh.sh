#!/bin/bash

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

function argCheck{
}

function userCheck{
}

function accessCheck{
}

function passwordCheck{
}

function addConnexion{
}

function removeConnexion{
}


