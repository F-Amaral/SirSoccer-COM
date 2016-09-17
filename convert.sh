#!/bin/bash
#
# String creator script for SirSoccer
# SIRLab-Laboratorio de Sistemas Inteligentes e Robotica  - 2015
# Main author : Felipe Amaral
# 
# SIRLab Members 2014: Johnathan Fercher, Oscar Neiva, Hebert Luiz, Lucas Marques
# SIRLab Members 2015: Johnathan Fercher, Oscar Neiva, Hebert Luiz, Felipe Amaral, Manoel Stilpen, Samantha Vilaça, Marina Barros
#
# This script was developed to create an API frame
# containing Robot (id motorApwm motorBpwm )
# Returns a string containing initial message header
# robot address+config (config,hexa,16 bits )(address,hexa, 64 bits)(config,hexa, 8 bits)
# command message (message, hexa, 24 bits)
# and checksum (checksum, hexa, 8 bits)
#
# Cheksum is calculated by excracting the 8 least significant bits from address+message, 
# and performing FF - sum
#

id=$1
cmdA=$2
cmdB=$3
header=(7E 00 10 00 00)
sum=0
fullmessage=0


##################### Verifies if there is a valid ID
case "$id" in 
0) address=(00 13 A2 00 40 A8 C4 C5 00 0A);;
1) address=(00 13 A2 00 40 A8 C4 B4 00 0A);;
2) address=(00 13 A2 00 40 A8 C4 FA 00 0A);;
*) echo "ID Invalido!!";exit 
esac


##################### Verifies if there is a parameter for both pwm, if not, exit

if test -n "$cmdA" && test -n "$cmdB" 
then
##################### Verifies if pwm on both motors is less than 255, if is, set direction indicator byte to 00
	if test "$cmdA" -lt 256 && test "$cmdB" -lt 256 
	then
##################### Verifies if pwm on both motors is positive
		if test "$cmdA" -ge 0 && test "$cmdB" -ge 0
		then
			if test "$cmdA" -ge 16 && test "$cmdB" -ge 16
			then
				cmdA=$(echo "obase=16;$cmdA" | bc)
				cmdB=$(echo "obase=16;$cmdB" | bc)
				message=(00 "$cmdA" "$cmdB" 0B)
			else
				message=(00 00 00 0B)
			fi	
		else
			echo "PWM Invalido"
			exit
		fi
#################### Verifies if pwm on motor A is greater than 255, if it is
#################### and pwm on motor b is lesser than 256, set direction indicator byte to 10
	elif test "$cmdA" -gt 255 && test "$cmdB" -lt 256
	then
#################### Verify if the pwm on motor A is lesser than 511
		if test "$cmdA" -lt 511 && test "$cmdB" -ge 0
		then
			if test "$cmdB" -ge 16
			then
				auxA=$(($cmdA-255))
				cmdA=$(echo "obase=16;$auxA" | bc)
				cmdB=$(echo "obase=16;$cmdB" | bc)
				message=(10 "$cmdA" "$cmdB" 0B) #0B
			else
				message=(10 "$cmdA" 00  0B) #0B
			fi
		else
			echo "PWM Invalido!"
			exit	
		fi
################### Verify if the pwm on motor B is greater than 255, if it is
################### and pwm on motor A is lesser than 256, set direction indicator byte to 01
	elif test "$cmdA" -lt 256 && test "$cmdB" -gt 255
	then
################### Verify if the pwm on motor B is lesser than 511
		if test "$cmdA" -ge 0 && test "$cmdB" -lt 511
		then
			if test "$cmdA" -ge 16
			then
				auxB=$(($cmdB-255))
				cmdA=$(echo "obase=16;$cmdA" | bc)
				cmdB=$(echo "obase=16;$auxB" | bc)
				message=(01 "$cmdA" "$cmdB" 0B) #
			else	
				message=(01 00 "$cmdB" 0B) #
			fi
		else
			echo "PWM Invalido!"
			exit
		fi
################## Verify if both pwm's are greater than 255, if they are, set direction indicator byte to 11
	elif test "$cmdA" -gt 255 && test "$cmdB" -gt 255
	then
################## Verify if both pwm's are lesser than 511
		if test "$cmdA" -lt 511 && test "$cmdB" -lt 511
		then
			auxA=$(($cmdA-255))
			auxB=$(($cmdB-255))
			cmdA=$(echo "obase=16;$auxA" | bc)
			cmdB=$(echo "obase=16;$auxB" | bc)
			message=(11 "$cmdA" "$cmdB" 0B) #
		else
			echo "PWM Invalido!"
			exit
		fi
	else 
		echo valor Invalido!
		exit
	fi
else
	echo "verifique o parametro!";
	exit
fi

################## Starts the checksum calculation operates on address

for i in "${address[@]}"
do
   sum="$sum"+"$i"
done
################## After summing all address bytes, sums the message bytes
for i in "${message[@]}"
do
   sum="$sum"+"$i"
done
################## Starts writing the finalMessage, concatenate header bytes on the final string
   for i in "${header[@]}"
do
fullmessage="$fullmessage"" ""$i"
done

################## Jumps to address bytes concatenating
   for i in "${address[@]}"
do
fullmessage="$fullmessage"" ""$i"
done
################## Now it's time to put the message together
   for i in "${message[@]}"
do
fullmessage="$fullmessage"" ""$i"
done

echo "$sum"
################## Cuts the 8 digits from the sum variable after it's converted to binary 
#sum=$(echo "obase=2;ibase=16;$sum" | bc ) #| tail -c 8)
sum=$(echo "obase=2;ibase=16;$sum" | bc | tail -c 9)
################## Reconvert to HEXADECIMAL
sum=$(echo "obase=16;ibase=2;$sum" | bc)
################## Aplly the checksum calculation formula
checksum=$(echo "obase=16;ibase=16;FF-$sum"| bc)
################## Puts the checksum on the end of the message
fullmessage="$fullmessage"" ""$checksum"

################## returns the full message
echo "$fullmessage"   |tr -d ' ' | cut -c 2-

