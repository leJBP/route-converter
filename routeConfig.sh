#!/bin/bash 

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

# Nom du fichier contenant les routes
routes="routes.txt"

res=""

# On crée le fichier d'équivalence de notation
touch equivalence.txt
echo "  réseaux       masque      passerelle" > equivalence.txt

# Lire le fichier contenant les routes ligne par ligne
while read line
do
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
    #echo $cidr
    network=$(subnetCidr $reseau $cidr)
    #echo $network
    destination=$(destinationShape $passerelle)
    #echo $destination

    # On concatène les résultats
    res="$res$network$destination, "

    # On ajoute les équivalences dans le fichier d'équivalence de notation 
    echo "$line => $network$destination" >> equivalence.txt

done < $routes

# On enregistre le résultat dans le fichier d'équivalence de notation
echo "transformation des routes effectuée, le résultat est dans le fichier equivalence.txt"
echo "" >> equivalence.txt
echo `echo option rfc3442-classless-static-routes $res | sed -e 's/.$/;/'` >> equivalence.txt
echo `echo option ms-classless-static-routes $res | sed -e 's/.$/;/'` >> equivalence.txt 