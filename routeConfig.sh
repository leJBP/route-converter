#!/bin/bash 

####################################################################
#                             FUNCTIONS                            #
####################################################################

# Display help
function showHelp()
{
    echo "routeConfig.sh - A script to convert routes to dhcpd.conf format"

    echo "Usage: routeConfig.sh [options]"

    echo "options:"
    echo "-h, --help                show brief help"
    echo "-i, --input               input file"
    echo "-o, --output              output file"
}

# Convert the mask in a windows standard into Linux standard
# Arguments: mask
function mask2cidr()
{
    IN=$1 # Arg function = mask
    IFS='.' # Internal Field Separator
    masklen=0 # Length of the mask

    # Loop on each byte of the mask
    for byte in $IN
    do
        bytelen=7 # byte length
        # Loop to compute successive powers of 2
        while [ "$byte" -gt 0 ]
        do
            let "pow=2**$bytelen"
            let "byte=$byte-$pow"
            ((masklen++))
            ((bytelen--))
        done

        # If the mask is not valid $byte < 0
        if [ "$byte" -lt 0 ]
        then
            masklen=-1
            break
        fi

    done
    echo $masklen # Return the mask length

}

# Convert the network in a windows standard into the isc dhcpd.conf standard
# Arguments: network, mask
# 10.117.0.0/16 -> 16, 10, 117
# 10.117.0.0/17 -> 17, 10, 117, 0
function subnetCidr()
{
    mask=$2 # Args function = mask
    IN=$1 # Args function = network
    IFS='.' #Internal Field Separator

    remainder=`expr $mask % 8` # Compute remainder of the division by 8
    div=`expr $mask / 8` # Compute the integer part of the division by 8
    len=`expr $div + $remainder` # Compute number of bytes to display
    res="" # Result of the function
    cpt=0 # Counter

    for byte in $IN
    do
        if [ "$cpt" -ge "$len" ]
        then
            break
        fi
        res="$res, $byte"
        ((cpt++))
    done
    echo "$mask$res"
}

# Convert the gateway in a windows standard into the isc dhcpd.conf standard
# Arguments: gateway
function destinationShape()
{
    IN=$1 # Arg function = gateway
    IFS='.' # Internal Field Separator

    res=""

    for byte in $IN
    do
        res="$res, $byte"
    done

    echo "$res"
}

# Unit tests
#mask2cidr 255.255.128.0
#subnetCidr 10.117.0.0 25
#destinationShape 11.15.78.4

####################################################################
#                                MAIN                              #
####################################################################

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
    echo "Input file is not specified"
    showHelp
    exit 1
fi

# If output file is not specified, we use the default one named out.txt
if [ -z "$output_file" ]
then
    output_file="out.txt"
fi

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# Create the output file
touch $output_file
echo "  network    mask   gateway" > $output_file

# Read the input file line by line
while read line
do

    # Check the format of the line
    format=`echo $line | sed -r 's/((\s|^)((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])){3}/1/'`

    if [ "$format" != "1" ]
    then
        echo "Le format de la ligne $line n'est pas valide"
        exit 1
    fi

    # Extract the mask
    mask=`echo $line | awk '{print $2}'`
    #echo $mask

    # Extract the network
    network=`echo $line | awk '{print $1}'`
    #echo $network

    # Extract the gateway
    gateway=`echo $line | awk '{print $3}'`
    #echo $gateway

    # Convert the mask in a Linux standard
    cidr=$(mask2cidr $mask)
    if [ "$cidr" -eq "-1" ]
    then
        echo "The following mask is not valid: $mask"
        exit 1
    fi

    # Convert the network in a Linux standard
    network=$(subnetCidr $network $cidr)
    # Convert the gateway in a Linux standard
    destination=$(destinationShape $gateway)

    # Concatenate the result
    res="$res$network$destination, "

    # Write the result in the output file
    echo "$line => $network$destination" >> $output_file

done < $input_file

# Save the result in the output file
echo "The process is finished, the result is saved in $output_file"
echo "" >> $output_file
echo `echo option rfc3442-classless-static-routes $res | sed -e 's/.$/;/'` >> $output_file
echo `echo option ms-classless-static-routes $res | sed -e 's/.$/;/'` >> $output_file 