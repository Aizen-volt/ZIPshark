# Author           : Mateusz Kaszubowski ( 193050 )
# Created On       : 2023-04-25
# Last Modified By : Mateusz Kaszubowski ( 193050 )
# Last Modified On : 2023-05-23
# Version          : prealpha 0.0.4
#
# Description      :
#
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

#!/bin/bash


# META
VERSION="prealpha 0.0.4"


#EXECUTION MANAGEMENT

EXECUTION_MODE="not selected" #bruteforce/dictionary
FILE="not selected"
MIN_LENGTH=0
MAX_LENGTH=100
CHARSET=("a".."z","A".."Z",0..9)


# INPUT FUNCTIONS
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


function is_positive_number {
	if [[ $1 =~ ^[0-9]+$ ]]
	then
		echo "$1"
	else
		echo "INVALID PARAMETER $1. INTEGER VALUE WAS EXPECTED"
		exit 1
	fi
}


function bruteforce {
	start=`date +%s`
	while read -r password; do
		unzip -qq -o -P $password test.zip 2>/dev/null
		exitcode=$? >> 8
		if [[ "$exitcode" == "0" ]]; then
			end=`date +%s`
			runtime=$((end-start))
			echo "Password found: $password"
			echo "Time elapsed: $runtime seconds"
			exit 0
		fi
	done < <(crunch $MIN_LENGTH 5 abcdefghijklmnopqrstuvwxyz)
	echo "Password not found"
	exit 0
}


#function dictionary {

#}

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

INPUT=""
while [[ "$INPUT" != "6" ]]; do
	printMenu
	read -p "Choose option: " INPUT
	case $INPUT in
		1)
			clear
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
			clear
			printTitle
			read -p "Enter archive file directory: " INPUT
			TEMP=$(find -name $INPUT -type f)
			if [[ "$TEMP" == "" ]]; then
				echo "File not found!"
				sleep 2
			else
				gzip -t $TEMP 2>/dev/null
				if [[ $? -eq 0 ]]; then
					if 7z l -slt $TEMP | grep -q "Encrypted = +"; then
						FILE=$TEMP
					else
						echo "File is not encrypted!"
						sleep 2
					fi
				else
					echo "File is not a zip archive!"
					sleep 2
				fi
			fi
			;;
		3)
			if [[ $EXECUTION_MODE == "bruteforce" ]]; then
				bruteforce
			elif [[ $EXECUTION_MODE == "dictionary"  ]]; then
				dictionary
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