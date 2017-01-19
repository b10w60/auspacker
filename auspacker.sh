#!/bin/bash

# Erkennt Dateiformat und erstellt Verzeichnis mit gleichem Namen (ohne Endung)
# im aktuellen Arbeitsverzeichnis. Entpackt die Datei dann in diesem
# Verzeichnis und entfernt sie dann ohne Nachfrage."
#
# Setzt voraus das folgende Pakete/Programme installiert sind:
# - file
# - unzip
# - gunzip
# - bunzip
# - tar
# - unrar

# ##############################################################################

# vars
workdir=$(pwd)
workfile=$1
keepworkfile=0

# funktionen
main(){
	# Datei auffindbar?
	if [ ! -f $workfile ]; then
		echo "ABBRUCH: Datei nicht gefunden!"
		exit 1
	fi

	# Dateinamen von Endung trennen
	IFS='.' read -r -a output <<< $1
	fname=${output[0]}

	# dateityp erkennen
	file --mime-type $1 > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		echo "ABBRUCH: Dateityp konnte nicht bestimmt werden. Ist das Paket 'file' installiert?"
		exit 1
	fi

	# richtigen entpacker ansteuern
	ftype=$(file --mime-type $1)
	if [ "${output[2]}" = "gz" ]; then targzfile; fi
	case "$ftype" in
		"$1: application/x-tar") tarfile;;
		"$1: application/zip") zipfile;;
		"$1: application/gzip") gzfile;;
		"$1: application/x-bzip2") bz2file;;
		"$1: application/x-rar") rarfile;;
		*) nichterkannt;;
	esac
}

rarfile(){
	verzeichnis_erzeugen
	if [ $keepworkfile -eq 0 ]; then mv $workfile $workdir;
	else cp $workfile $workdir; fi
	cd $workdir
	unrar x $workfile
	rm -rf $workfile
	nacharbeiten
}

tarfile(){
	verzeichnis_erzeugen
	if [ $keepworkfile -eq 0 ]; then mv $workfile $workdir;
	else cp $workfile $workdir; fi
	cd $workdir
	tar xf $workfile
	rm -rf $workfile
	nacharbeiten
}

targzfile(){
	verzeichnis_erzeugen
	if [ $keepworkfile -eq 0 ]; then mv $workfile $workdir;
	else cp $workfile $workdir; fi
	cd $workdir
	tar xfz $workfile
	rm -rf $workfile
	nacharbeiten
	exit 0
}

gzfile(){
	verzeichnis_erzeugen
	if [ $keepworkfile -eq 0 ]; then mv $workfile $workdir;
	else cp $workfile $workdir; fi
	cd $workdir
	gunzip $workfile
	nacharbeiten
}

bz2file(){
	verzeichnis_erzeugen
	if [ $keepworkfile -eq 0 ]; then mv $workfile $workdir;
	else cp $workfile $workdir; fi
	cd $workdir
	bunzip2 $workfile
	nacharbeiten
}


zipfile(){
	verzeichnis_erzeugen
	unzip $workfile -d $workdir
	if [ $? -ne 0 ]; then
		echo "ABBRUCH: Das entpacken hat nicht geklappt."
		exit 1
	fi
	nacharbeiten
}

verzeichnis_erzeugen(){
	workdir=$(pwd)/$fname
	mkdir -p $workdir
	if [ $? -ne 0 ]; then
		echo "ABBRUCH: Verzeichnis $workdir/$fname konnte nicht erstellt werden"
		exit 1
	fi
}

nacharbeiten(){
	if [ $keepworkfile -eq 0 ]; then
		rm -rf $workfile
		if [ $? -ne 0 ]; then
			echo "ABBRUCH: Ursprungsdatei $workfile konnte nicht gelöscht werden."
			exit 1
		fi
	fi
}

nichterkannt(){
	echo "Dateityp konnte nicht erkannt werden. 'auspacker.sh -hilfe' für weiter Infos diesbezüglich."
	exit 1
}

hilfe(){
	echo "Aufruf: auspacker.sh [Dateiname] [Option]"
	echo
	echo "Erkennt Dateiformat und erstellt Verzeichnis mit gleichem Namen (ohne Endung) im aktuellen Arbeitsverzeichnis. Entpackt die Datei dann in diesem Verzeichnis und entfernt sie dann ohne Nachfrage."
	echo
	echo "Optionen:"
	echo "-k     Verhindert das die Ursprungsdatei gelöscht wird"
	echo
	echo "Diese Dateiformate werden unterstützt:"
	echo "- .tar"
	echo "- .tar.gz"
	echo "- .gz"
	echo "- .zip"
	echo "- .bz2"
	echo "- .rar"
	echo
	echo "Falls weitere Dateiformate erwünscht sind, mich über GitHub (b10w60) kontaktieren."
	echo
	exit 0
}
# ------------------------------------------------------------------------------

# Programmstart:
# Datei übergeben?
if [ -z $1 ]; then
	echo "ABBRUCH: Keine Datei übergeben."
	exit 1
fi

if [ -n $2 ]; then
	case "$2" in
		-k|k ) keepworkfile=1;;
	esac
fi

case "$1" in
	-h|-H|-help|-Help|-hilfe|-Hilfe|--help|--Help|--hilfe|--Hilfe) hilfe;;
	*)	main $1;;
esac

exit 0
