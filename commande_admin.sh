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


## Fonction relative à la fonction "host" permettant de gérer les machines ##

# Fonction permettant de constituer une liste des utilisateurs ayant les accès à une machine
function viewAccessMachine {
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi

	machine=$1
	access=$(grep "$machine" $fichier_machine | cut -d ";" -f2 | sed 's/,/ /g')
	echo "Utilisateur ayant accès à la machine $machine :$access" > $(tty)
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

		oldAccess=$(grep "$machine" $fichier_machine | cut -d ";" -f2)
		newAccess="$oldAccess$user,"
		sed -i "s/$machine;$oldAccess/$machine;$newAccess/" $fichier_machine

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

		oldAccess=$(grep "$machine" $fichier_machine | cut -d ";" -f2)
		newAccess=$(echo $oldAccess | sed "s/$user,//g")
		sed -i "s/$machine;$oldAccess/$machine;$newAccess/" $fichier_machine

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

	machine=$1
	echo "$machine;,admin," >> $fichier_machine

	addAccess $machine
}


# Fonction permettant de supprimer une machine dans le fichier machine
function removeMachine {
	argCheck $# 0
	if [ $? -ne 1 ]; then
		error 1
		return 0
	fi

	machine=$1

	machineCheck $machine
	if [[ $? -ne 1 ]] ; then
		return 0
	fi

	sed -i "/^$machine;/d" $fichier_machine
	sed -i "/;$machine;/d" $fichier_connexion
}


# Fonction permettant d'ajouter ou de supprimer une machine dans le fichier machine
function commande-host {
	argCheck $# 2
	if [ $? -ne 1 ]; then
		error 1
		return 0
	fi

	adminCheck
	if [[ $? -ne 1 ]] ; then
		return 0
	fi

	option=$1
	machine=$2

	if [[ $option == "-a" ]] ; then
		addMachine $machine
	elif [[ $option == "-s" ]] ; then
		removeMachine $machine
	fi
}


## Fonction relatives à la fonction "user" permettant de gérer les utilisateurs ##

# Fonction permettant d'ajouter un utilisateur dans le fichier user
function addUser {
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi

	user=$1
	read -sp "Entrez le mot de passe du nouvel utilisateur : " password
	echo ""
	read -p "Entrez le prénom et nom du nouvel utilisateur (Prénom Nom) : " nom
	read -p "Entrez l'adresse mail du nouvel utilisateur : " mail

	echo "$user;$password;$nom;$mail;¤" >> $fichier_user	
}

# Fonction permettant de supprimer un utilisateur dans le fichier user
function removeUser {
	argCheck $# 1
	if [ $? -ne 1 ]; then
		error 1
		return 0
	fi

	user=$1

	userCheck $user
	if [[ $? -ne 1 ]] ; then
		return 0
	fi

	sed -i "/^$user;/d" $fichier_user
	sed -i "/;$user;/d" $fichier_connexion
}

function commande-user {
	argCheck $# 2
	if [ $? -ne 1 ]; then
		error 1
		return 0
	fi

	adminCheck
	if [[ $? -ne 1 ]] ; then
		return 0
	fi

	option=$1
	user=$2

	if [[ $option == "-a" ]] ; then
		addUser $user
	elif [[ $option == "-s" ]] ; then
		removeUser $user
	fi	
}


## Fonction relatives à la fonction "wall" ##
# Fonction permettant d'envoyer un message à tous les utilisateurs connectés, et optionnellement à tous les utilisateurs non-connectés
function commande-wall {
	# Demande comme argument :
	#	1) l'option "-n" facultative, permettant de lancer l'envoi des messages à tous les utilisateurs non-connectés
	#	2) le message à envoyer

	# On vérifie le nombre d'argument et récupère le message
	if [[ $1 == "-n" ]] ; then
		argCheck $# 2
		if [ $? -ne 1 ]; then
			return 0
		fi
		message=$2
	else
		argCheck $# 1
		if [ $? -ne 1 ]; then
			return 0
		fi
		message=$1
	fi

	# On vérifie que l'utilisateur est connecté à la machine
	connectedCheck $dest_user $dest_machine
	if [[ $? -ne 1 ]] ; then
		echo "L'utilisateur $dest_user n'est pas connecté à la machine $dest_machine. Echec de l'envoi du message." > $(tty)
		return 0
	fi

	# On récupère la liste de toutes les connexion à l'utilisateur et machine
	for dest_user in $(cut -d ";" -f 1 $fichier_user) ; do
		for ligne in $(grep "$dest_user;" $fichier_connexion) ; do 
			dest_terminal=$(echo $ligne | cut -d ";" -f 1 | sed 's/\//_/g')
			if [[ $ligne == $(grep "$dest_terminal" $fichier_connexion | tail -1) ]] ; then # On vérifie que c'est la dernière connexion du terminal (qu'il n'est pas connecté à un autre utilisateur et/ou machine)
				# On envoie le message aux utilisateurs connectés à la machine
				echo "De admin à $dest_user : $message" > $(echo $dest_terminal | sed 's/_/\//g')
			else
				# On envoie le message aux utilisateurs non-connectés à la machine en le sauvegardant dans le fichier user
				if [[ $1 == "-n" ]] ; then
					texte=$(grep "$dest_user;" $fichier_user)
					newTexte="$texte¤De admin à $dest_user : $message¤"
					sed -i "s/$texte/$newTexte/g" $fichier_user
				fi
			fi
		done
	done
	

	echo "Message envoyé" > $(tty)
}

# Fonction permettant de lire les messages sauvegardés
function readSavedMessage {
	# Demande comme argument :
	#	1) l'utilisateur dont on veut lire les messages

	# On vérifie le nombre d'argument
	argCheck $# 1
	if [ $? -ne 1 ]; then
		return 0
	fi

	# On récupère les messages sauvegardés et les affiche
	texte=$(grep "$1;" $fichier_user | cut -d ";" -f 5)
	if [[ $texte == "¤" ]] ; then
		echo "Aucun message reçu" > "$(tty)"
	else
		echo "Message reçu : " > "$(tty)"
		echo $texte | cut -d ";" -f 5  | sed 's/¤/\n/g' > "$(tty)"
	fi
}


## Fonction relatives à la fonction "afinger" ##

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