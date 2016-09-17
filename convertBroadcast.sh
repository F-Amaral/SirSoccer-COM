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
# Returns a string containing initial MESSAGE HEADER
# robot ADDRESS+config (config,hexa,16 bits )(ADDRESS,hexa, 64 bits)(config,hexa, 8 bits)
# command MESSAGE (MESSAGE, hexa, 24 bits)
# and CHECK_SUM (CHECK_SUM, hexa, 8 bits)
#
# ChekSUM is calculated by excracting the 8 least significant bits from ADDRESS+MESSAGE, 
# and performing FF - SUM
#

#id=$1
HEADER=(7E 00 18 00 00)
SUM=0
FULL_MESSAGE=0

##################### Verifies if there is a valid ID
#case "$id" in 
#0) ADDRESS=(00 13 A2 00 40 A8 C4 C5 00 0A);;
#1) ADDRESS=(00 13 A2 00 40 A8 C4 B4 00 0A);;
#2) ADDRESS=(00 13 A2 00 40 A8 C4 FA 00 0A);;
#*) echo "ID Invalido!!";exit 
#esac

ADDRESS=(00 00 00 00 00 00 FF FF 00)

CALCULATE_PWM () { 
	##################### Verifies if there is a parameter for both pwm, if not, exit
	CMD_A="$1"
	CMD_B="$2"

	if test -n "$CMD_A" && test -n "$CMD_B" 
	then
	##################### Verifies if pwm on both motors is less than 255, if is, set direction indicator byte to 00
		if test "$CMD_A" -lt 256 && test "$CMD_B" -lt 256 
		then
	##################### Verifies if pwm on both motors is positive
			if test "$CMD_A" -ge 0 && test "$CMD_B" -ge 0
			then
				if test "$CMD_A" -ge 16 && test "$CMD_B" -ge 16
				then
					CMD_A=$(echo "obase=16;$CMD_A" | bc)
					CMD_B=$(echo "obase=16;$CMD_B" | bc)
					MESSAGE=(00 "$CMD_A" "$CMD_B") #0D
 				else
					MESSAGE=(00 00 00 0B)
				fi	
			else
				echo "PWM Invalido! ABORTANDO!!!" 1>&2
				exit 1
			fi
	#################### Verifies if pwm on motor A is greater than 255, if it is
	#################### and pwm on motor b is lesser than 256, set direction indicator byte to 10
		elif test "$CMD_A" -gt 255 && test "$CMD_B" -lt 256
		then
	#################### Verify if the pwm on motor A is lesser than 511
			if test "$CMD_A" -lt 511 && test "$CMD_B" -ge 0
			then
				if test "$CMD_B" -ge 16
				then
					AUX_A=$(($CMD_A-255))
					CMD_A=$(echo "obase=16;$AUX_A" | bc)
					CMD_B=$(echo "obase=16;$CMD_B" | bc)
					MESSAGE=(10 "$CMD_A" "$CMD_B") #0B 0D
				else
					MESSAGE=(10 "$CMD_A" 00) #0B 0D
				fi
			else
				echo "PWM Invalido! ABORTANDO!!!" 1>&2
				exit 1
			fi
	################### Verify if the pwm on motor B is greater than 255, if it is
	################### and pwm on motor A is lesser than 256, set direction indicator byte to 01
		elif test "$CMD_A" -lt 256 && test "$CMD_B" -gt 255
		then
	################### Verify if the pwm on motor B is lesser than 511
			if test "$CMD_A" -ge 0 && test "$CMD_B" -lt 511
			then
				if test "$CMD_A" -ge 16
				then
					AUX_B=$(($CMD_B-255))
					CMD_A=$(echo "obase=16;$CMD_A" | bc)
					CMD_B=$(echo "obase=16;$AUX_B" | bc)
					MESSAGE=(01 "$CMD_A" "$CMD_B" ) #0D
				else	
					MESSAGE=(01 00 "$CMD_B" ) #0D
				fi
			else
				echo "PWM Invalido! ABORTANDO!!!" 1>&2
				exit 1
			fi
	################## Verify if both pwm's are greater than 255, if they are, set direction indicator byte to 11
		elif test "$CMD_A" -gt 255 && test "$CMD_B" -gt 255
		then
	################## Verify if both pwm's are lesser than 511
			if test "$CMD_A" -lt 511 && test "$CMD_B" -lt 511
			then
				AUX_A=$(($CMD_A-255))
				AUX_B=$(($CMD_B-255))
				CMD_A=$(echo "obase=16;$AUX_A" | bc)
				CMD_B=$(echo "obase=16;$AUX_B" | bc)
				MESSAGE=(11 "$CMD_A" "$CMD_B" ) #0D
			else
				echo "PWM Invalido! ABORTANDO!!!" 1>&2
				exit 1
			fi
		else 
			echo "Valor Invalido! ABORTANDO!!!" 1>&2
			exit 1
		fi
	else
		echo "Verifique os parametros! ABORTANDO!!!" 1>&2
		exit 1
	fi
	FUNCTION_RETURN=""
	for i in "${MESSAGE[@]}"
	do
		FUNCTION_RETURN+="$i "
	done
	echo "$FUNCTION_RETURN"
}

MESSAGE=(0A$(CALCULATE_PWM "$1" "$2" || exit 1) 0B)
ROBOT_0=$?
MESSAGE+=($(CALCULATE_PWM "$3" "$4" || exit 1) 0C)
ROBOT_1=$?
MESSAGE+=($(CALCULATE_PWM "$5" "$6" || exit 1) 0D)
ROBOT_2=$?

#echo "Mensagem Parcial: "
#for i in "${MESSAGE[@]}"
#do
#	echo -n "$i"
#done
#echo "\n"
################## Starts the CHECK_SUM calculation operates on ADDRESS
for i in "${ADDRESS[@]}"
do
   SUM="$SUM+$i"
done

################## After SUMming all ADDRESS bytes, SUMs the MESSAGE bytes
for i in "${MESSAGE[@]}"
do
   SUM="$SUM""+""$i"
done

################## Starts writing the finalMessage, concatenate HEADER bytes on the final string
for i in "${HEADER[@]}"
do
	FULL_MESSAGE+="$i"
done

################## Jumps to ADDRESS bytes concatenating
for i in "${ADDRESS[@]}"
do
	FULL_MESSAGE+="$i"
done

################## Now it's time to put the MESSAGE together
for i in "${MESSAGE[@]}"
do
	FULL_MESSAGE+="$i"
done

################## Cuts the 8 digits from the SUM variable after it's converted to binary 
################## Cutting um more char to compensate for the control char LINE_FEED "0x0A" in hex 
SUM=$(echo "obase=2;ibase=16;$SUM" | bc | tail -c 9)

################## Reconvert to HEXADECIMAL
SUM=$(echo "obase=16;ibase=2;$SUM" | bc)
################## Aplly the CHECK_SUM calculation formula
CHECK_SUM=$(echo "obase=16;ibase=16;FF-$SUM"| bc)

################## Puts the CHECK_SUM on the end of the MESSAGE
FULL_MESSAGE+="$CHECK_SUM"

################## returns the full MESSAGE
if [[ "$ROBOT_0" == "0" && "$ROBOT_1" == "0" && "$ROBOT_2" == "0" ]] ; then 
	echo "$FULL_MESSAGE"   |tr -d ' ' | cut -c 2-  
	exit 0
else 
	exit 1 
fi 

