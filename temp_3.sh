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



# Fonction permettant de convertir le timestamp en date
function timestampToDate {
    timestamp=$1
    year=$(echo $timestamp | cut -c 1-4)
    month=$(echo $timestamp | cut -c 5-6)
    day=$(echo $timestamp | cut -c 7-8)
    hour=$(echo $timestamp | cut -c 9-10)
    minute=$(echo $timestamp | cut -c 11-12)
    seconde=$(echo $timestamp | cut -c 13-14)
    
    case $month in
        01)
            month=Jan;;
        02)
            month=Feb;;
        03)
            month=Mar;;
        04)
            month=Apr;;
        05)
            month=May;;
        06)
            month=Jun;;
        07)
            month=Jul;;
        08)
            month=Aug;;
        09)
            month=Sep;;
        10)
            month=Oct;;
        11)
            month=Nov;;
        12)
            month=Dec;;
    esac
    
    echo "$day $month $year $hour:$minute:$seconde"
}

ligne=$(cat $fichier_connexion | tail -1)
date=$(echo $ligne | cut -d ";" -f 4)
date=$(timestampToDate $date)
echo "Date : $date"