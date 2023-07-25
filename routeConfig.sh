#!/bin/bash 

function showHelp()
{
    echo "routeConfig.sh - A script to convert routes to dhcpd.conf format"

    echo "Usage: routeConfig.sh [options]"

    echo "options:"
    echo "-h, --help                show brief help"
    echo "-i, --input               input file"
    echo "-o, --output              output file"
}

# Convertir le masque au format CIDR
function mask2cidr()
{
    IN=$1 #Argument de la fonction = masque
    IFS='.' #Internal Field Separator
    masklen=0 #Longueur du masque

    #Parcours des octets du masque
    for octet in $IN
    do
        octetlen=7 #Longueur d'un l'octet
        # Boucle pour calculer les puissances sucessives de 2
        while [ "$octet" -gt 0 ]
        do
            let "pow=2**$octetlen"
            let "octet=$octet-$pow"
            ((masklen++))
            ((octetlen--))
        done

        # Si octet < 0 alors le masque n'est pas valide
        if [ "$octet" -lt 0 ]
        then
            masklen=-1
            break
        fi

    done
    echo $masklen #Retourne la longueur du masque

}

# Convertir le sous-réseaux dans le format attendu
# 10.117.0.0/16 -> 16, 10, 117
# 10.117.0.0/17 -> 17, 10, 117, 0
function subnetCidr()
{
    mask=$2
    IN=$1 #Argument de la fonction = réseau
    IFS='.' #Internal Field Separator

    reste=`expr $mask % 8` #On calcul le reste de la division par 8
    div=`expr $mask / 8` #On calcul le quotient de la division par 8
    taille=`expr $div + $reste` #On calcul le nomobre d'octet à mettre dans la configuration

    res=""
    cpt=0
    for octet in $IN
    do
        if [ "$cpt" -ge "$taille" ]
        then
            break
        fi
        res="$res, $octet"
        ((cpt++))
    done
    echo "$mask$res"
}

function destinationShape()
{
    IN=$1 #Argument de la fonction = passerelle
    IFS='.' #Internal Field Separator

    res=""

    for octet in $IN
    do
        res="$res, $octet"
    done

    echo "$res"
}
# Tests unitaires des fonctions

#mask2cidr 255.255.128.0
#subnetCidr 10.117.0.0 25
#destinationShape 11.15.78.4

POSITIONAL_ARGS=()

# Initialize our own variables:
output_file=""
input_file=""
res="" # result of the transformation

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
        output_file="$2"
        shift # past argument
        shift # past value
        ;;
        -i|--input)
        input_file="$2"
        shift # past argument
        shift # past value
        ;;
        -h|--help)
        showHelp
        exit 0
        ;;
        *)    # unknown option
        POSITIONAL_ARGS+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
done

# If input file is not specified exit
if [ -z "$input_file" ]
then
    echo "Le fichier d'entrée n'est pas spécifié"
    showHelp
    exit 1
fi

# If output file is not specified, we use the default one named out.txt
if [ -z "$output_file" ]
then
    output_file="out.txt"
fi

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# On crée le fichier d'équivalence de notation
touch $output_file
echo "  réseau    masque   passerelle" > $output_file

# Lire le fichier contenant les routes ligne par ligne
while read line
do

    # Check the format of the line
    format=`echo $line | sed -r 's/((\s|^)((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])){3}/1/'`

    if [ "$format" != "1" ]
    then
        echo "Le format de la ligne $line n'est pas valide"
        exit 1
    fi

    # On récupère le masque
    masque=`echo $line | awk '{print $2}'`
    #echo $masque

    # On récupere le réseau
    reseau=`echo $line | awk '{print $1}'`
    #echo $reseau

    # On récupere la passerelle
    passerelle=`echo $line | awk '{print $3}'`
    #echo $passerelle

    # On appel les fonctions pour mettre en forme les données
    cidr=$(mask2cidr $masque)
    if [ "$cidr" -eq "-1" ]
    then
        echo "Le masque $masque n'est pas valide"
        exit 1
    fi

    network=$(subnetCidr $reseau $cidr)
    destination=$(destinationShape $passerelle)

    # On concatène les résultats
    res="$res$network$destination, "

    # On ajoute les équivalences dans le fichier d'équivalence de notation 
    echo "$line => $network$destination" >> $output_file

done < $input_file

# On enregistre le résultat dans le fichier d'équivalence de notation
echo "transformation des routes effectuée, le résultat est dans le fichier $output_file"
echo "" >> $output_file
echo `echo option rfc3442-classless-static-routes $res | sed -e 's/.$/;/'` >> $output_file
echo `echo option ms-classless-static-routes $res | sed -e 's/.$/;/'` >> $output_file 