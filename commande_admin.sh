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
	read -p "Entrez le prénom et nom du nouvel utilisateur (Prénom Nom) : " nom
	read -p "Entrez l'adresse mail du nouvel utilisateur : " mail

	echo "$user;$password;$nom;$mail;" >> $fichier_user	
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
