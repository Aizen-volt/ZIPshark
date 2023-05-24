# Author           : Mateusz Kaszubowski ( 193050 )
# Created On       : 2023-04-25
# Last Modified By : Mateusz Kaszubowski ( 193050 )
# Last Modified On : 2023-05-23
# Version          : release 1.0.0
#
# Description      :
#
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)


# ERROR CODES
# 1 - missing dependencies
# 2 - package download failed
# 3 - dictionary download failed
# 4 - password not found
# 12 - unsupported distribution


#!/bin/bash


# META
VERSION="release 1.0.0"


#EXECUTION MANAGEMENT
EXECUTION_MODE="not selected" #bruteforce/dictionary
FILE="not selected"
MIN_LENGTH=""
MAX_LENGTH=""
SMALL="true"
CAPITAL="true"
DIGITS="true"
SPECIAL="true"
VERBAL="false"
DICTIONARY=""
DEFAULT_DICTIONARY="realhuman_phill.txt"


function checkPackage {
	printTitle
	if ! [ -x "$(command -v $1)" ]; then
		echo "Error: This script requires $1 command to be installed" >&2
		echo "Do you want to install it? (y/n)"
		read -n 1 -s -r INPUT
		if [[ "$INPUT" == "y" ]]; then
			DISTRIBUTION=$(cat /etc/*-release | grep -w "ID" | cut -d "=" -f 2 | tr -d '"')
			echo "$DISTRIBUTION"
			if [[ "$DISTRIBUTION" == "ubuntu" ]]; then
				sudo apt install $1
			elif [[ "$DISTRIBUTION" == "fedora" ]]; then
				sudo dnf install $1
			elif [[ "$DISTRIBUTION" == "centos" ]]; then
				sudo yum install $1
			else
				echo "Your distribution is not supported!"
				exit 12
			fi
			if [[ "$?" != "0" ]]; then
				clear
				echo "An error occured while installing $1!"
				exit 2
			fi
			return
		else
			exit 1
		fi
	fi
}


function checkDependencies {
	checkPackage crunch
	checkPackage unzip
	checkPackage p7zip-full
	checkPackage wget
}


function fetchDictionary {
	DICTIONARY_EXISTS="true"

	if [ ! -d "/var/lib/zipshark" ]; then
		echo "Dictionary directory not found!"
		sudo mkdir /var/lib/zipshark
		DICTIONARY_EXISTS="false"
	fi
	TEMP=$(find /var/lib/zipshark -name $DEFAULT_DICTIONARY -type f)
	if [[ "$TEMP" == "" ]]; then
		DICTIONARY_EXISTS="false"
	fi

	if [[ "$DICTIONARY_EXISTS" == "false" ]]; then
		echo "Default dictionary not found!"
		echo "Do you want to download it? (y/n)"
		read -n 1 -s -r INPUT
		if [[ "$INPUT" == "y" ]]; then
			printTitle
			sudo wget https://crackstation.net/files/crackstation-human-only.txt.gz
			if [[ "$?" != "0" ]]; then
				clear
				echo "An error occured while downloading dictionary!"
				exit 3
			fi
			sudo mv crackstation-human-only.txt.gz /var/lib/zipshark/$DEFAULT_DICTIONARY.gz
			sudo gunzip /var/lib/zipshark/$DEFAULT_DICTIONARY.gz
			DICTIONARY=/var/lib/zipshark/$DEFAULT_DICTIONARY
		else
			echo "No dictionary selected!"
			sleep 2
			return
		fi
	else
		DICTIONARY=/var/lib/zipshark/$DEFAULT_DICTIONARY
	fi
}


function printPasswordFound {
	printTitle
	echo "Password found!"
	echo "Password: $1"
	echo "Time elapsed: $2 seconds"
	echo ""
	exit 0
}


function printPasswordNotFound {
	printTitle
	echo "Password could not be found! :(("
	echo "Try adjusting search parameters"
	echo ""
	exit 4
}


function print_version {
	printTitle
	echo $VERSION
	echo "Created by: Mateusz Kaszubowski"
	echo ""
	echo "Press any key to continue..."
	read -n 1 -s
}


function print_help {
	printTitle
	echo "----------------------------------------------"
	echo "                    HELP                      "
	echo "----------------------------------------------"
	echo "-v, --version – info about version/author"
    	echo "-h, --help – quick help, for more info see manual"
    	echo "-b, --brute-force – try all possible combinnations amongst characters defined by user (or amongst all characters if charset was not defined using -c, --charset)"
   	echo "-d, --dictionary <file_dir> - try breaching using words contained in dictionary pointed with <fire_dir>"
    	echo "-c, --charset – choose characters to be used during brute-force"
	echo "	a – small letters"
	echo "	A – capital letters"
	echo "	0 – digits"
	echo "	! – special characters"
    	echo "-l, --length-min – set minimal (inclusively) length of generated passwords"
    	echo "-L, --length-max – set maximal (inclusively) length of generated passwords"
	echo ""
	echo "Press any key to continue..."
	read -n 1 -s
}


function dictionaryMenu {
	INPUT=""
	while [[ "$INPUT" != "3" ]]; do
		printTitle
		echo "Dictionary mode"
		echo "If there is no dictionary specified, built-in one will be used"
		echo "Dictionary file should contain one word per line - otherwise recovery process may not work as intended"
		echo "Beware that turning on verbal mode significantly slows down the process"
		echo ""
		echo "1. Dictionary file: $DICTIONARY"
		echo "2. Verbal mode: $VERBAL"
		echo "3. Run"
		echo ""
		echo "4. Return to main menu"
		echo ""
		read -p "Choose option: " INPUT
		case $INPUT in
			1)
				printTitle
				read -p "Enter dictionary file directory: " INPUT
				TEMP=$(find -name $INPUT -type f)
				if [[ "$TEMP" == "" ]]; then
					echo "File not found!"
					sleep 2
				else
					DICTIONARY=$TEMP
				fi
				;;
			2)
				if [[ "$VERBAL" == "true" ]]; then
					VERBAL="false"
				else
					VERBAL="true"
				fi
				;;
			3)	
				if [[ "$DICTIONARY" == "" ]]; then
					fetchDictionary
				fi
				if [[ "$DICTIONARY" == "" ]]; then
					continue
				fi
				if [[ "$VERBAL" == "true" ]]; then
					dictionaryVerbal
				else
					dictionary
				fi
				;;
			4)
				return
				;;
			*)
				echo "Invalid option!"
				sleep 2
				;;
		esac
	done
}


function dictionary {
	clear
	start=`date +%s`
	while read -r password; do
		unzip -qq -o -P $password $FILE 2>/dev/null
		exitcode=$? >> 8
		if [[ "$exitcode" == "0" ]]; then
			end=`date +%s`
			runtime=$((end-start))
			printPasswordFound $password $runtime
		fi
	done < $DICTIONARY
	printPasswordNotFound
}


function dictionaryVerbal {
	LINES_COUNT=$(wc -l < $DICTIONARY)
	COUNTER=0
	clear
	start=`date +%s`
	while read -r password; do
		clear
		COUNTER=$((COUNTER+1))
		PERCENTAGE=$((COUNTER*100/LINES_COUNT))
		echo "Checked $COUNTER/$LINES_COUNT ($PERCENTAGE%)"
		echo "Checking: $password"
		unzip -qq -o -P $password $FILE 2>/dev/null
		exitcode=$? >> 8
		if [[ "$exitcode" == "0" ]]; then
			end=`date +%s`
			runtime=$((end-start))
			printPasswordFound $password $runtime
		fi
	done < $DICTIONARY
	printPasswordNotFound
}


function bruteforceMenu {
	INPUT=""
	while [[ "$INPUT" != "6" ]]; do
		printTitle
		echo "Bruteforce mode"
		echo "It is highly recommended to specify parameters below to shorten search time"
		echo "Beware that turning on verbal mode significantly slows down the process"
		echo ""
		echo "1. Min password length: $MIN_LENGTH"
		echo "2. Max password length: $MAX_LENGTH"
		echo "3. Charset: ${CHARSET[*]}"
		echo "4. Verbal mode: $VERBAL"
		echo "5. Run"
		echo ""
		echo "6. Return to main menu"
		echo ""
		read -p "Choose option: " INPUT
		case $INPUT in
			1)
				printTitle
				read -p "Enter min password length: " INPUT
				if [[ $INPUT =~ ^[0-9]+$ ]]; then
					if [[ "$MAX_LENGTH" != "" ]]; then
						if [[ $INPUT -gt $MAX_LENGTH ]]; then
							echo "Min length cannot be greater than max length!"
							sleep 2
						else
							MIN_LENGTH=$INPUT
						fi
					else
						MIN_LENGTH=$INPUT
					fi
				else
					echo "Invalid parameter! Non-negative integer value expected"
					sleep 2
				fi
				;;
			2)
				printTitle
				read -p "Enter max password length: " INPUT
				if [[ $INPUT =~ ^[0-9]+$ ]]; then
					if [[ "$MIN_LENGTH" != "" ]]; then
						if [[ $INPUT -lt $MIN_LENGTH ]]; then
							echo "Max length cannot be smaller than min length!"
							sleep 2
						else
							MAX_LENGTH=$INPUT
						fi
					else
						MAX_LENGTH=$INPUT
					fi
				else
					echo "Invalid parameter! Non-negative integer value expected"
					sleep 2
				fi
				if [[ $MAX_LENGTH -gt 128 ]]; then
					echo "Max length cannot be greater than 128"
					sleep 2
				fi
				;;
			3)
				INPUT=""
				while [ "$INPUT" != 5 ]; do
					printTitle
					echo "Picking a range changes its appearance in generated passwords:"
					echo "1. {a..z} : $SMALL"
					echo "2. {A..Z} : $CAPITAL"
					echo "3. {0..9} : $DIGITS"
					echo "4. {!../} : $SPECIAL"
					echo ""
					echo "5. Return to bruteforce menu"
					echo ""
					read -p "Choose option: " INPUT
					case $INPUT in
						1)
							if [[ "$SMALL" == "true" ]]; then
								SMALL="false"
							else
								SMALL="true"
							fi
							;;
						2)
							if [[ "$CAPITAL" == "true" ]]; then
								CAPITAL="false"
							else
								CAPITAL="true"
							fi
							;;
						3)
							if [[ "$DIGITS" == "true" ]]; then
								DIGITS="false"
							else
								DIGITS="true"
							fi
							;;
						4)
							if [[ "$SPECIAL" == "true" ]]; then
								SPECIAL="false"
							else
								SPECIAL="true"
							fi
							;;
						5)
							;;
						*)
							echo "Invalid option!"
							sleep 2
							;;
					esac
				done
				;;
			4)
				if [[ "$VERBAL" == "true" ]]; then
					VERBAL="false"
				else
					VERBAL="true"
				fi
				;;
			5)	
				if [[ "$SMALL" == "false" && "$CAPITAL" == "false" && "$DIGITS" == "false" && "$SPECIAL" == "false" ]]; then
					echo "Setting each charset range to false is not allowed!"
					sleep 2
					continue
				fi
				if [[ "$MIN_LENGTH" == "" ]]; then
					MIN_LENGTH="1"
				fi
				if [[ "$MAX_LENGTH" == "" ]]; then
					MAX_LENGTH="128"
				fi
				if [[ "$VERBAL" == "true" ]]; then
					bruteforceVerbal
				else
					bruteforce
				fi
				;;
			6)
				return
				;;
			*)
				;;
		esac
		INPUT=""
	done
}


function bruteforce {
	CHARSET=""
	if [[ "$SMALL" == "true" ]]; then
		CHARSET=$CHARSET"abcdefghijklmnopqrstuvwxyz"
	fi
	if [[ "$CAPITAL" == "true" ]]; then
		CHARSET=$CHARSET"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	fi
	if [[ "$DIGITS" == "true" ]]; then
		CHARSET=$CHARSET"0123456789"
	fi
	if [[ "$SPECIAL" == "true" ]]; then
		CHARSET=$CHARSET"!\"#$%&'()*+,-./:;<=>?@[\]^_\`{|}~"
	fi
	clear
	start=`date +%s`
	while read -r password; do
		unzip -qq -o -P $password $FILE 2>/dev/null
		exitcode=$? >> 8
		if [[ "$exitcode" == "0" ]]; then
			end=`date +%s`
			runtime=$((end-start))
			printPasswordFound $password $runtime
		fi
	done < <(crunch $MIN_LENGTH $MAX_LENGTH $CHARSET)
	printPasswordNotFound
}


function bruteforceVerbal {
	CHARSET=""
	if [[ "$SMALL" == "true" ]]; then
		CHARSET=$CHARSET"abcdefghijklmnopqrstuvwxyz"
	fi
	if [[ "$CAPITAL" == "true" ]]; then
		CHARSET=$CHARSET"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	fi
	if [[ "$DIGITS" == "true" ]]; then
		CHARSET=$CHARSET"0123456789"
	fi
	if [[ "$SPECIAL" == "true" ]]; then
		CHARSET=$CHARSET"!\"#$%&'()*+,-./:;<=>?@[\]^_\`{|}~"
	fi

	if [[  "$MAX_LENGTH" != "128" ]]; then
		CHARSET_LENGTH=${#CHARSET}
		CHARSET_LENGTH=$((CHARSET_LENGTH-2))
		COMBINATIONS=0
		for (( i=$MIN_LENGTH - 1; i<$MAX_LENGTH; i++ )); do
			TEMP=1
			for (( j=0; j<=$i; j++ )); do
				TEMP=$((TEMP*CHARSET_LENGTH))
			done
			COMBINATIONS=$((COMBINATIONS+TEMP))
		done
	fi
	
	COUNTER=0
	clear
	start=`date +%s`
	while read -r password; do
		clear
		COUNTER=$((COUNTER+1))
		if [[  "$MAX_LENGTH" != "128" ]]; then
			PERCENTAGE=$((COUNTER*100/COMBINATIONS))
			echo "Checked $COUNTER/$COMBINATIONS ($PERCENTAGE%)"
		else
			echo "Checked $COUNTER"
		fi
		echo "Checking: $password"
		unzip -qq -o -P $password $FILE 2>/dev/null
		exitcode=$? >> 8
		if [[ "$exitcode" == "0" ]]; then
			end=`date +%s`
			runtime=$((end-start))
			printPasswordFound $password $runtime
		fi
	done < <(crunch $MIN_LENGTH $MAX_LENGTH $CHARSET)
	printPasswordNotFound
}


function printTitle {
	clear
	echo "
                                                                                                                                                 
                                                                                                                                                 
			ZZZZZZZZZZZZZZZZZZZIIIIIIIIIIPPPPPPPPPPPPPPPPP                        hhhhhhh                                                 kkkkkkkk           
			Z:::::::::::::::::ZI::::::::IP::::::::::::::::P                       h:::::h                                                 k::::::k           
			Z:::::::::::::::::ZI::::::::IP::::::PPPPPP:::::P                      h:::::h                                                 k::::::k           
			Z:::ZZZZZZZZ:::::Z II::::::IIPP:::::P     P:::::P                     h:::::h                                                 k::::::k           
			ZZZZZ     Z:::::Z    I::::I    P::::P     P:::::P         ssssssssss   h::::h hhhhh         aaaaaaaaaaaaa  rrrrr   rrrrrrrrr   k:::::k    kkkkkkk
			        Z:::::Z      I::::I    P::::P     P:::::P       ss::::::::::s  h::::hh:::::hhh      a::::::::::::a r::::rrr:::::::::r  k:::::k   k:::::k 
			       Z:::::Z       I::::I    P::::PPPPPP:::::P      ss:::::::::::::s h::::::::::::::hh    aaaaaaaaa:::::ar:::::::::::::::::r k:::::k  k:::::k  
			      Z:::::Z        I::::I    P:::::::::::::PP       s::::::ssss:::::sh:::::::hhh::::::h            a::::arr::::::rrrrr::::::rk:::::k k:::::k   
			     Z:::::Z         I::::I    P::::PPPPPPPPP          s:::::s  ssssss h::::::h   h::::::h    aaaaaaa:::::a r:::::r     r:::::rk::::::k:::::k    
			    Z:::::Z          I::::I    P::::P                    s::::::s      h:::::h     h:::::h  aa::::::::::::a r:::::r     rrrrrrrk:::::::::::k     
			   Z:::::Z           I::::I    P::::P                       s::::::s   h:::::h     h:::::h a::::aaaa::::::a r:::::r            k:::::::::::k     
			ZZZ:::::Z     ZZZZZ  I::::I    P::::P                 ssssss   s:::::s h:::::h     h:::::ha::::a    a:::::a r:::::r            k::::::k:::::k    
			Z::::::ZZZZZZZZ:::ZII::::::IIPP::::::PP               s:::::ssss::::::sh:::::h     h:::::ha::::a    a:::::a r:::::r           k::::::k k:::::k   
			Z:::::::::::::::::ZI::::::::IP::::::::P               s::::::::::::::s h:::::h     h:::::ha:::::aaaa::::::a r:::::r           k::::::k  k:::::k  
			Z:::::::::::::::::ZI::::::::IP::::::::P                s:::::::::::ss  h:::::h     h:::::h a::::::::::aa:::ar:::::r           k::::::k   k:::::k 
			ZZZZZZZZZZZZZZZZZZZIIIIIIIIIIPPPPPPPPPP                 sssssssssss    hhhhhhh     hhhhhhh  aaaaaaaaaa  aaaarrrrrrr           kkkkkkkk    kkkkkkk
                                                                                                                                                 
                                                                                                                                                 
"
}


function printMenu {
	printTitle
	echo "Welcome to ZIPshark!"
	echo "To start password recovery process, determine execution mode and archive file directory"
	echo ""
	echo "1. Execution mode: $EXECUTION_MODE"
	echo "2. Archive file: $FILE"
	echo "3. Run"
	echo "4. Help"
	echo "5. Version info"
	echo "6. Exit"
	echo ""
}


function toggleMainMenu {
	INPUT=""
	while [[ "$INPUT" != "6" ]]; do
		printMenu
		read -p "Choose option: " INPUT
		case $INPUT in
			1)
				printTitle
				echo "Choose execution mode:"
				echo "1. Bruteforce"
				echo "2. Dictionary"
				echo ""
				read -p "Choose option: " INPUT
				case $INPUT in
					1)
						EXECUTION_MODE="bruteforce"
						;;
					2)
						EXECUTION_MODE="dictionary"
						;;
					*)
						echo "Invalid option!"
						echo "No changes made"
						sleep 2
						;;
				esac
				;;
			2)
				printTitle
				read -p "Enter archive file directory: " INPUT
				TEMP=$(find -name $INPUT -type f)
				if [[ "$TEMP" == "" ]]; then
					echo "File not found!"
					sleep 2
				else
					if 7z l -slt $TEMP 2> /dev/null | grep -q "Encrypted = +"; then
						FILE=$TEMP
					else
						echo "Selected file is not encrypted zip!"
						sleep 2
					fi
				fi
				;;
			3)	
				if [[ "$FILE" == "not selected" ]]; then
					echo "No file selected!"
					sleep 2
					continue
				fi
				if [[ "$EXECUTION_MODE" == "bruteforce" ]]; then
					bruteforceMenu
				elif [[ "$EXECUTION_MODE" == "dictionary" ]]; then
					dictionaryMenu
				else
					echo "No execution mode chosen! Try help for more info"
					sleep 2
				fi
				;;
			4)
				print_help
				;;
			5)
				print_version
				;;
			6)
				clear
				exit 0
				;;
			*)
				echo "Invalid option!"
				sleep 2
				;;
		esac
		INPUT=""
	done
}


# CORE
####################################################################
checkDependencies
toggleMainMenu
####################################################################
