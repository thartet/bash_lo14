# Fonction permettant de se connecter à une machine alors que l'on est déjà connecté à une machine du réseau virtuel
function commande-rconnect {
	# Demande comme argument :
	#	1) le nom de la machine à laquelle l'utilisateur veut se connecter
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi

	machine=$1

	# On récupère l'utilisateur actuel
	user=$(grep "^$(tty | sed 's/\//_/g')" $fichier_connexion | tail -1 | cut -d ";" -f 2)

	connexion $user $machine

}


# Fonction permettant de se connecter à un utilisateur alors que l'on est déjà connecté à une utilisateur du réseau virtuel
function commande-su {
	# Demande comme argument :
	#	1) le nom de l'utilisateur à laquelle l'utilisateur veut se connecter
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi

	user=$1

	# On récupère la machine actuelle
	machine=$(grep "^$(tty | sed 's/\//_/g')" $fichier_connexion | tail -1 | cut -d ";" -f 3)

	connexion $user $machine

}


## Fonctions relatives à la fonction write ##

# Fonction permettant d'envoyer un message à un utilisateur connecté
function commande-write {
	# Demande comme argument :
	#	1) le nom de l'utilisateur et le nom de la machine à qui on veut envoyer le message (nom_utilisateur@nom_machine)
	#	2) le message à envoyer
	argCheck $# 2
	if [ $? -ne 1 ]; then
		return 0
	fi

	# On récupère le nom de l'utilisateur et le nom de la machine
	dest_user=$(echo $1 | cut -d "@" -f 1)
	dest_machine=$(echo $1 | cut -d "@" -f 2)

	# On récupère le message
	message=$2

	# On vérifie que l'utilisateur existe
	userCheck $dest_user

	# On vérifie que la machine existe
	machineCheck $dest_machine

	# On vérifie que l'utilisateur est connecté à la machine
	connectedCheck $dest_user $dest_machine
	if [[ $? -ne 1 ]] ; then
		echo "L'utilisateur $dest_user n'est pas connecté à la machine $dest_machine. Echec de l'envoi du message." > $(tty)
		return 0
	fi

	# On récupère le nom d'utilisateur et le nom de la machine de l'utilisateur qui envoie le message
	terminal=$(tty | sed 's/\//_/g')
	user=$(grep "$terminal;" $fichier_connexion | tail -1 | cut -d ";" -f 2)
	machine=$(grep "$terminal;" $fichier_connexion | tail -1 | cut -d ";" -f 3)

	# On récupère la liste de toutes les connexion à l'utilisateur et machine
	for ligne in $(grep "$dest_user;$dest_machine" $fichier_connexion) ; do 
        dest_terminal=$(echo $ligne | cut -d ";" -f 1 | sed 's/\//_/g')
        if [[ $ligne == $(grep "$dest_terminal" $fichier_connexion | tail -1) ]] ; then # On vérifie que c'est la dernière connexion du terminal (qu'il n'est pas connecté à un autre utilisateur et/ou machine)
			# On envoie le message aux utilisateurs connectés à la machine
            echo "De $user@$machine à $dest_user@$dest_machine : $message" > "$(echo $dest_terminal | sed 's/_/\//g')"
        fi
 	done

	echo "Message envoyé" > "$(tty)"
}

#Fonction permettant d'accéder à l'ensemble des utilisateurs connectés sur la machine

function commande-who {
	#Ne demande pas d'argument
	argCheck $# 0
 	if [ $? -ne 1 ] ; then	
		return 0
	fi

	#On récupère la machine actuelle
	machine=$(grep "^$(tty) | sed 's/\//_/g')" $fichier_connexion | tail -1 | cut -d ";" -f 3)
	while read ligne
			do
				IFS=';' read -ra ADDR <<< "$ligne"
				if [ $machine == ${ADDR[2]} ]; then
					date=($timestampToDate ${ADDR[3]})
					echo "Utilisateur ${ADDR[1]}, date et heure de connexion : $date"
				fi
			done < connexion
}

# Fonction rusers permettant d'afficher les utilisateurs connectés au réseau virtuel
function commande-rusers {
	#Ne demande pas d'argument
	argCheck $# 0
 	if [ $? -ne 1 ] ; then	
		return 0
	fi

	while read ligne # Affiche le fichier connexion.log dans lequel on trouve tous les utilisateurs connectés
		do
			IFS=';' read -ra ADDR <<< "$ligne"
			date=($timestampToDate ${ADDR[3]})
			echo "Utilisateur ${ADDR[1]}, date et heure de connexion : $date"
		done < connexion
		return 0;
}

#Fonction rhost permettant de renvoyer la liste des machines connectées au réseau virtuel
function commande-rhost {
	#Ne demande pas d'argument
	argCheck $# 0
 	if [ $? -ne 1 ] ; then	
		return 0
	fi

	while read ligne # Affiche le fichier machine dans lequel se trouve la liste des machines
		do
			IFS=';' read -ra ADDR <<< "$ligne"
			echo "Machine : ${ADDR[0]}"
		done < machine
		return 0;
}

#Fonction finger permettant d'obtenir des information sur les utilisateurs
function commande-finger {
	#Demande comme argument
	#1) Le nom de l'utilisateur sur lequel on souhaite obtenir des informations
	argCheck $# 1
	if [ $? -ne 1 ] ; then	
		return 0
	fi

	user=$1

	while read ligne # Affiche le fichier user dans lequel se trouve la liste des utilisateurs et leurs informations
		do
			IFS=';' read -ra ADDR <<< "$ligne"
			if [ $user == ${ADDR[0]}]
			echo "Informations sur l'utilisateur $user : Nom complet - ${ADDR[2]} et adresse mail : ${ADDR[3]}"
			fi
		done < user
		return 0;
}

#Fonction permettant de changer son mot de passe
function commande-passwd {

	# On récupère l'utilisateur actuel
	user=$(grep "^$(tty | sed 's/\//_/g')" $fichier_connexion | tail -1 | cut -d ";" -f 2)

	read -sp "Nouveau mot de passe" nouveauMdp

	#On vérifie que le mot de passe n'est pas vide
	if [ -z "$nouveauMdp" ]; then
    	echo "Le mot de passe ne peut pas être vide"
    	return 0;
	fi

 	read -sp "Confirmer votre nouveau mot de passe " nouveauMdp2

	#On vérifie si les mots de passe sont identiques
	if [ "$nouveauMdp" != "$nouveauMdp2" ]; then
    	echo "Erreur : Les mots de passe ne correspondent pas"
    	return 0;
  	fi

  	#On modifie le mot de passe dans le fichier user
  	sed -i "s/^$user;.*;\(.*\);\(.*\);\(.*\)$/$user;$nouveauMdp;\1;\2;\3/" $fichier_user
}
