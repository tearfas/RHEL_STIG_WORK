#!/bin/bash

DEF_PERMS=$(for i in $(rpm -Va | grep -E '^.{1}M|^.{5}U|^.{6}G' | cut -d " " -f 4,5); do for j in $(rpm -qf "$i");do rpm -ql "$j" --dump | cut -d " " -f 1,5,6,7 | grep "$i";done;done | awk '{print $1, $2=int(substr($2,3,6))}' | sort -u )

echo "$DEF_PERMS" >> /tmp/"$(hostname -f)_def_perms.txt"

#### Replace White Spaces With Colon #####
DEF_PERMS="${DEF_PERMS// /:}"

for  FILELIST in $DEF_PERMS
do

   readarray -d : arr <<< "$FILELIST"

    FILENAME=${arr[*]:0:1}
    FDEFPERM=${arr[*]:1:1}

    #echo file name is "$FILENAME"
    #echo file Perm is "$FDEFPERM"

  if [ -e "$FILENAME" ]; then
        #### Pull The Existing Permissions Before Remediation ####
        EXTGPERM=$(stat -c '%a' "$FILENAME")

        #### Save Existing File Permissions To a File ####
        echo "$EXTGPERM $FILENAME" >> /tmp/"$(hostname -f)_extg_perms.txt"

        #### Change Permisson Only If Existing Permission is Greater Than The Default Permission ####
         if [[ "$EXTGPERM" -gt "$FDEFPERM" ]]; then
            sudo chmod "$FDEFPERM" "$FILENAME"
         fi
        ##### Pull Permissions after Remiediation and Save to a File #####
        FXDPERM=$(stat -c '%a %n' "$FILENAME")
        echo "$FXDPERM" >> /tmp/"$(hostname -f)_fxd_perms.txt"
  fi
done
