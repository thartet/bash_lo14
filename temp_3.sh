chemin=$(pwd)
fichier_connexion=$chemin/connexion
fichier_machine=$chemin/machine
fichier_user=$chemin/user

terminal=$(tty | sed 's/\//_/g')
user="moussouc"
machine="m1"

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

date=$(dateToTimestamp)

echo "$(grep "$terminal;$user;$machine" connexion | tail -1)"
echo "$terminal;$user;$machine;$date"
sed -i "s/$(grep "$terminal;$user;$machine" connexion | tail -1)/$terminal;$user;$machine;$date/" $fichier connexion