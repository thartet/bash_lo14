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

	# On récupère l'utilisateur actuel
	machie=$(grep "^$(tty | sed 's/\//_/g')" $fichier_connexion | tail -1 | cut -d ";" -f 3)

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
            echo "De $user@$machine à $dest_user@$dest_machine : $message" > $(echo $dest_terminal | sed 's/_/\//g')
        fi
 	done

	echo "Message envoyé" > $(tty)
}


