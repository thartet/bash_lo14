#!/bin/bash
chemin=$(pwd)
echo $chemin
fichier_user=$chemin/bash_lo14/user
echo $fichier_user
fichier_machine=$chemin/bash_lo14/machine
echo $fichier_machine
fichier_connexion=$chemin/bash_lo14/connexion


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


function argCheck { # Fonction permettant de vérifier le nombre d'arguments
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

function userCheck { # Fonction permettant de vérifier qu'un utilisateur existe
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter
	echo "Vérification de l'existence de l'utilisateur"
	argCheck $# 1
	if [ $? -eq 1 ]; then
		user="$1"
		while read ligne
			do
				nom_user=$(echo $ligne | sed 's/^\(.*\);.*;.*;.*$/\1/g');
				if [ $user == $nom_user ]; then 
					echo "Existence de l'utilisateur confirmée";
					return 1;
				fi
			done < $fichier_user
		error 3
		return 0
	fi
}

function machineCheck { # Fonction permettant de vérifier qu'un utilisateur existe
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
				if [ $machine == $(echo $ligne | sed 's/^.*;\(.*\);.*$/\1/g') ]; then # On trouve la machine dans le fichier 
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

function passwordCheck {
	# Demande comme argument : 
	#	1) le nom d'utilisateur avec lequel l'utilisateur veut se connecter
	argCheck $# 1
	if [ $? == 1 ]; then
		user="$1"
		read -sp "Entrez le mot de passe de $user : " password
		while read ligne
			do
                nom_user=$(echo $ligne | sed 's/^\(.*\);.*;.*;.*$/\1/g')
				if [ $user == $nom_user ] ; then # On trouve le user dans le fichier 
					correct_password=$(echo $ligne | sed 's/^.*;\(.*\);.*;.*$/\1/g') ; # On récupère le mot de passe correct
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


# Cette fonction implémente un serveur.  
# La fonction doit être invoqué avec les arguments :                   
# 	1) le port sur lequel le serveur attend ses clients 
#	2) le nom de la machine
function runMachine {
	if [[ $# -ne 2 ]] ; then
		echo "usage: $(basename $0) PORT USER"
		exit -1
	fi
	port="$1"
	machine="$2"

	fifo="/tmp/$machine-fifo-$$"

	trap nettoyage EXIT

	# on crée le tube nommé

	[ -e "fifo" ] || mkfifo "$fifo"

	accept-loop $port $fifo
}

function nettoyage { rm -f "$fifo"; }


function accept-loop {
	# Demande comme argument : 
	#	1) le port sur lequel le serveur attend ses clients
	#	2) le tunnel utilisé pour lancer le serveur
	port="$1"
	fifo="$2"
	while true; 
		do
			interaction < "$fifo" | netcat -l -p "$port" > "$fifo"
		done
}

function commande-non-comprise {
   echo "Le serveur ne peut pas interprêter cette commande"
}

# La fonction interaction lit les commandes du client sur entrée standard 
# et envoie les réponses sur sa sortie standard. 
#
# 	CMD arg1 arg2 ... argn                   
#                     
# alors elle invoque la fonction :
#                                                                            
#         commande-CMD arg1 arg2 ... argn                                      
#                                                                              
# si elle existe; sinon elle envoie une réponse d'erreur.                    

function interaction {
    local cmd args
    while true; do
	read cmd args || exit -1
	fun="commande-$cmd"
	if [[ "$(type -t $fun)" = "function" ]] ; then
	    $fun $args
	else
	    commande-non-comprise $fun $args
	fi
    done
}

function commande-test() {
       echo test
}

function commande-rvsh {
	# Demande comme argument : 
	#	1) la commande -connect ou -admin
	#	2) le nom d'utilisateur avec lequel l'utilisateur veut se connecter, 
	#	3) le nom de la machine à laquelle il veut se connecter
    echo "here"
	continuer=0
	if [[ $1 == "-admin" ]] ; then
        echo $#
        echo "argcheck"
        argCheck $# 1
		if [[ $? -eq 1 ]] ; then
            echo "hey"
			user="admin"
			machine="hostroot"
			continuer=1
		fi
	else
		argCheck $# 3
		if [[ $? -eq 1 ]] ; then
			user="$2"
			machine="$3"
			continuer=1
		fi
	fi

    echo "$user"
    echo "$machine"
    echo "$continuer"

	if [[ $continuer -eq 1 ]] ; then
        echo "userCheck"
		userCheck $user
		if [[ $? -eq 1 ]] ; then
            echo "passwordcheck"
            passwordCheck $user
            if [[ $? -eq 1 ]] ; then
                echo "machinecheck"
                machineCheck $machine
                if [[ $? -eq 1 ]] ; then
                    echo "accesscheck"
                    accessCheck $user $machine
                    if [[ $? -eq 1 ]] ; then
                        echo "salut"
                        port=$(grep "$machine" $fichier_machine | sed "s/\(.*\);.*;.*/\1/")
                        echo $port
                        declare -i port=port+8080
                        echo $port
                        if [[ $(grep "$machine" $fichier_connexion) != "\n" ]] ; then
                            echo "yo"
                            runMachine $port $machine &
                        else
                            echo "ya"
                        fi
                        netcat localhost $port
                    fi
                fi
            fi
        fi
	fi
}

echo "$1"


if [[ "$1" == "-admin" ]] ; then
    echo "youhou"
	commande-rvsh $1
elif [[ "$1" == "-connect" ]] ; then
    commande-rvsh $1 $2 $3
else
    echo "Commande non reconnue"
fi

# Bonjour,Je suis en train de faire un projet de réseau, et je bloque sur une partie. Je dois faire un serveur qui permet de se connecter à des machines distantes. Pour cela, j'ai un fichier qui contient les machines disponibles, et un autre qui contient les utilisateurs. J'ai aussi un fichier qui contient les accès aux machines. J'ai donc fait un script qui permet de se connecter à une machine distante, mais je ne sais pas comment faire pour que le serveur se lance sur la machine distante. Voici mon script :Merci d'avance pour votre aide

