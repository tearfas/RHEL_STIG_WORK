#!/bin/bash
 
DEF_PERMS=$(for i in `rpm -Va | grep -E '^.{1}M|^.{5}U|^.{6}G' | cut -d " " -f 4,5`; do for j in `rpm -qf $i`;do rpm -ql $j --dump | cut -d " " -f 1,5,6,7 | grep $i;done;done | awk '{print $1, $2=int(substr($2,3,6))}' | sort -u )

echo "$DEF_PERMS" >> /tmp/$(hostname -f)_def_perms.txt 

for  FILELIST in "$DEF_PERMS"
do
  FILENAME=$(echo $FILELIST | awk '{ print $1 }' )
  FDEFPERM=$(echo $FILELIST | awk '{ print $2 }' )

  if [ -e "$FILENAME" ]; then
        # Pull the Existing permissions
        EXTGPERM=`stat -c '%a' $FILENAME`
   
		# Change Permisson Only If Existing Permission is Greater Than The Default Permission
         if [ $EXTGPERM -gt $FDEFPERM ]; then
            sudo chmod $FDEFPERM $FILENAME
         fi
  fi
done
