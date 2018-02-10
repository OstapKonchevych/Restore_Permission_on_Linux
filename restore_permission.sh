#!/bin/bash	

# Name: Restore permissions
# Description: Restore permissions in file and folder on operating system Linux 
# Version: 1.0
# Auhor: Ostap Konchevych
# Website: www.konchevych.pp.ua
# Github: 

 
 WorkDir="" #Temporary files folder
 PathSaveTable="" #The folder in which the tables with file and directory folders will be stored will be stored
 SleepSecond=0.7

 InitScript()
 {
	 clear
	 echo -n "Loading..."
	 
	 if [ $UID -ne 0 ]
	  then
	   AlertMessage "\t[Error]" 31 40
	   echo "You need to run this script from root user"
	   exit 1 ; sleep $SleepSecond ; clear
	 else
	  if [ ! -d "$WorkDir" ]
	   then
	    mkdir -p "$WorkDir"
	   elif [ ! -d "$PathSaveTable" ]
	    then
	     mkdir -p "$PathSaveTable"
	    else
	     AlertMessage "\t[Успішно]" 32 40  
	     sleep $SleepSecond ; clear 
	     	     
	     return 0
	  fi
	 fi
 }

 AlertMessage()
 {
	 Message=$1
	 TextColor=$2
	 BackgroundColor=$3
	 
	 echo -e '\E['${TextColor}';'${BackgroundColor}'m'"\033[1m"${Message}"\033[0m"
 }
 
 PressKey()
 {
   if [ -z "$1" ]
    then
      AlertMessage "\nPress Enter to continue" 33 40
      read tmp
    else
     echo "$1" #This string is testing
    fi   
 }
 
 Start()
 {
   select Action in "View available tables" "Create new table" "Restore in tables" "Exit"
    do
     break
    done
    
    case "$Action" in
  	 "View available tables")
  	   if [ -z $(ls "$PathSaveTable"/*.rpt) ]
  	    then
  	     AlertMessage "Tables missing..." 33 40
  	     sleep $SleepSecond ; clear
  	     Start
  	    else
  	     cd "$PathSaveTable"
  	     ls *.rpt
  	     PressKey ; clear
  	     Start
  	   fi  
  	 ;;
  	 "Create new table") 
  	  echo -e "Create new table...\n Enter the desired table name without extension."
  	  read TableName
  	   
  	   if [ -f "$PathSaveTable""/""$TableName.rpt" ]
  	    then
  	     AlertMessage "WARNING! A table with this name already exists." 31 40
  	     PressKey ; clear
  	     Start
  	    else
  	     echo -e "\nEnter the path to the folder. You need to enter the full path."
  	     read DIR
  	     
  	      if [ ! -d "$DIR" ]
  	       then
  	        AlertMessage "No such file or directory" 31 40
  	        PressKey ; clear
  	        Start
  	       else
  	         cd "$DIR"
  	        GenerateTable "$TableName"
  	      fi
  	   fi
  	 ;;
  	 "Restore in tables")
  	  echo "Restoring\n"
  	 ;; 
  	 "Exit")
  	  AlertMessage "Goodbye..." 32 40
  	  sleep $SleepSecond ; clear 
  	  exit 0
  	 ;;
  	 *)
  	  AlertMessage "# undefined command" 31 40
  	  sleep $SleepSecond ; clear
  	  Start
  	 esac   
 }
 
 ConvertPermissions()
 {
	Permissions=$1
	Number=0
	
    for i in `seq 0 2`
     do
     case ${Permissions:$i:1} in
	  "r")
       Number=`expr $Number + 4`
		;;
	  "w")
	   Number=`expr $Number + 2`
	    ;;
	  "x")
	   Number=`expr $Number + 1`	
	    ;;
	  *) 
	   Number=`expr $Number + 0` 
	 esac
    done	
   echo -n "$Number" 
 }
 
 GenerateTable()
 {
  TableName=$1
   
  du -a > $WorkDir"/ListFileF.txt"
  cat /dev/null > $WorkDir"/ListFileS.txt"
  
  index=0
	 while read line
	  do
	  
	   for i in `seq 0 ${#line}`
	     do
	      if [ "${line:$i:2}" = "./" ]
	       then
	        echo ${line:`expr $i + 2`:${#line}} >> $WorkDir"/ListFileS.txt"
	       fi 
	     done
	     
	    index=`expr $index + 1`
	 done < $WorkDir"/ListFileF.txt"
	 
	 rm -f $WorkDir"/ListFileF.txt"
	
	 cat /dev/null > "$PathSaveTable""/""$TableName.rpt"
	 
	pwd >> "$PathSaveTable""/""$TableName.rpt"
	 index=0
	 while read line
	  do
	  #
	    StringDataFile=$(ls -ld "$line")
	    DataExplode "$StringDataFile" " "
	   RWX=${explodeString[0]}
	   RWX=${RWX:1:9}
	    
	   rwx=()
	     for i in `seq 0 2`
	      do
	       tmp=${StringDataFile:`expr 3 \* $i`:3}
	       rwx[$i]=$(ConvertPermissions "$tmp")
	     done
   
	  echo "${rwx[0]}${rwx[1]}${rwx[2]}:${explodeString[2]}:${explodeString[3]}:$line" >> "$PathSaveTable""/""$TableName.rpt"
	  echo "$line"
	  
	    index=`expr $index + 1`
	 done < $WorkDir"ListFileS.txt"
	 
	 rm -f $WorkDir"ListFileS.txt"
 
 }
 
 DataExplode()
 {
    local string=$1 
    local Separator=$2 
    local positionSeparator=(0) 
    explodeString=()
    local keyPositionSeparator=0 
    
    for i in $(seq 0 `expr ${#string} - 1`)
    do
    if [ "${string:$i:1}" = "$Separator" ]
    then
    
     if [ "${string:`expr $i + 1`:1}" = " " ]
      then
       continue 
      fi
      
    if [ "$keyPositionSeparator" -ne 0 ]
     then
      tmp=`expr ${positionSeparator[$keyPositionSeparator]} + 1`
      explodeString[$keyPositionSeparator]=${string:$tmp:`expr $i - $tmp`}
      keyPositionSeparator=`expr $keyPositionSeparator + 1`
      positionSeparator[$keyPositionSeparator]="$i"
     else
      explodeString[$keyPositionSeparator]=${string:${positionSeparator[$keyPositionSeparator]}:`expr $i - ${positionSeparator[$keyPositionSeparator]}`}
      keyPositionSeparator=`expr $keyPositionSeparator + 1`
      positionSeparator[$keyPositionSeparator]="$i"
     fi
    fi
    done
    
 }

 

InitScript
Start
