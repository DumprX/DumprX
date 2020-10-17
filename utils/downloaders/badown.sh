#!/bin/bash

#
#    Copyright (C) 2020  stck-lzm at https://github.com/stck-lzm/badown
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

function url_str {
   echo $1\
      | awk '{gsub("-","+"); gsub("_","/"); gsub(",",""); print}'
}
function json_req {
   wget -q -O- --post-data="$1" --header='Content-Type:application/json' "https://g.api.mega.co.nz/cs$2"
}
function key_solver {
   echo -n $1 \
      | base64 --decode --ignore-garbage \
      2> /dev/null \
      | xxd -p \
      | tr -d '\n'
}
function json_post {
   echo $2\
      | awk -v c=$1 -F'"' '{for(i = 1; i <= NF; i++)
   {if($i==c)
      if((c=="t")||(c=="s")||(c=="ts")) 
	 {gsub(/[[:punct:]]/,"",$(i+1));print $(i+1);}
      else
	 {print $(i+2);}
      }
   }'
}
function key_dec {
   local var=$(key_solver "$(url_str $key)")
   echo $(url_str $1)\
      | openssl enc -a -d -A -aes-128-ecb -K $var -iv "00000000000000000000000000000000" -nopad \
      2> /dev/null \
      | base64
}
function size {
   local i=0
   local var=$1
   local pad=$(((4-${#var}%4)%4))
   for i in $(seq 1 $pad); do
      var="$var="
   done
   echo $var
}
function meta_dec_key {
   local var
   var[0]=$(( 0x${1:00:16} ^ 0x${1:32:16} ))
   var[1]=$(( 0x${1:16:16} ^ 0x${1:48:16} ))
   meta_key=$(printf "%016x" ${var[*]})
   meta_iv="${1:32:16}0000000000000000"
}
function meta_dec {
   echo -n $2 \
      | openssl enc -a -A -d -aes-128-cbc -K $1 -iv "00000000000000000000000000000000" -nopad \
      | tr -d '\0' \
      2> /dev/null
}
function mega_link_vars {
   if [[ "$1" ==  *"/#"* ]]; then
      id=`echo $1 | awk -F'!' '{print $2}'`
      key=`echo $1 | awk -F'!' '{print $3}'`
      fld=`echo $1 | awk -F'!' '{print $1}'`
   else
      fld=`echo $1 | awk '{gsub(/[^\/]*$/,"");print}'`
      id=`echo $1 | awk -F'/' '{print $NF}' | awk -F# '{print $1}'`
      key=`echo $1 | awk -F'/' '{print $NF}' | awk -F# '{print $2}'`
   fi
}
function file_downdec {
   wget -O "$2".tmp $speed -q --show-progress "$1"
   cat "$2.tmp" \
      | openssl enc -d -aes-128-ctr -K $3 -iv $4 \
      > "$2"
   rm -f "$2".tmp
}
function file_down {
   wget -O "$2".tmp $speed -q --show-progress "$1"
   mv "$2".tmp "$2"
}
function tree_gen {
   local i=0
   while [[ $i -lt $2 ]] && ! [[ ${names[i]} == "$1" ]]; do
      let i++
   done
   if ! [[ $i == $2 ]]; then
      tree_gen ${parents[i]} $2
      meta_dec_key "$(key_solver $(key_dec $(size ${keys[i]})))"
      file_name="$(json_post 'n' "$(meta_dec $meta_key $(size $(url_str ${attrs[i]})))")"
      path=$path/$file_name
   fi
}
function error {
	echo -e "\033[31merror\e[0m: $1" 1>&2
	exit 1
}
function mega {
   mega_link_vars $1
   if [ "${fld: -1}" == "F" ] || [[ "$fld" == *"folder"* ]];then
      json_req '[{"a":"f","c":1,"ca":1,"r":1}]' "?id=&n=$id" > .badown.tmp
      [[ $(file .badown.tmp) == *"gzip"* ]] && response1=$(cat .badown.tmp | gunzip) || response1=$(cat .badown.tmp)
      keys=($(json_post 'k' $response1 | awk -F':' '{print $2}'))
      names=($(json_post 'h' $response1 ))
      types=($(json_post 't' $response1 ))
      attrs=($(json_post 'a' $response1 ))
      sizes=($(json_post 's' $response1 ))
      parents=($(json_post 'p' $response1 ))
      for i in $(seq 0 $((${#types[@]}-1)));do 
	 unset path
	 tree_gen ${parents[i]} $((${#types[@]}-1))
	 meta_dec_key "$(key_solver $(key_dec $(size ${keys[i]})))"
	 file_name="$(json_post 'n' "$(meta_dec $meta_key $(size $(url_str ${attrs[i]})))")"
	 path=$path/$file_name
	 if [ ${types[i]} == 1 ];then
	    sleep .5;mkdir -p "$PWD$path"
	 elif [ ${types[i]} == 0 ];then
	    file_url=$(json_post 'g' $(json_req "[{\"a\":\"g\",\"g\":1,\"n\":\"${names[i]}\"}]" "?id=&n=$id"))
	    #echo $file_url
	    #echo $file_name
	    #echo $meta_key
	    #echo $meta_iv
	    file_downdec $file_url "$file_name" $meta_key $meta_iv 
	    sleep .5;mv "$file_name" "$PWD$path"
	 fi
      done
   elif [ "${fld: -1}" == "#" ] || [[ "$fld" == *"file"* ]];then
      meta_dec_key $(key_solver $(url_str $key))
      name_key=$(url_str $(json_post 'at' $(json_req "[{\"a\":\"g\", \"p\":\"$id\"}]" '?id=&ak=')))
      file_name="$(json_post 'n' "$(meta_dec $meta_key $(size $name_key))")"
      file_url=$(json_post 'g' $(json_req "[{\"a\":\"g\",\"g\":1,\"p\":\"$id\"}]" '?'))
      file_downdec $file_url "$file_name" $meta_key $meta_iv 
   fi
}
function zippyshare {
   wget -q -O .badown.tmp $1
   var0=$(echo $1 | awk -F".com" '{print $1".com"}')
   cat .badown.tmp | grep -B8 "dlbutton" > .badown2.tmp
   var1=$(cat .badown2.tmp | grep href | grep document.getElementById | awk -F'"' '{print $2}')
   var2modulo=$(cat .badown2.tmp | grep "%" | awk -F'(' '{print $3}' | awk -F' ' '{print $1}')
   var3a=$(cat .badown2.tmp | grep "var a = function" | awk -F' ' '{print $6}' | awk -F'}' '{print $1}')
   var3bp=$(cat .badown2.tmp | grep "var b = function" | awk -F' ' '{print $8}' | awk -F'}' '{print $1}')
   var3b=$((var3a+var3bp))
   var3cp=$(cat .badown2.tmp | grep "var c = function" | awk -F' ' '{print $8}' | awk -F'}' '{print $1}')
   var3c=$((var3b+var3cp))
   var3dp=$(cat .badown2.tmp | grep omg | grep "class=" | awk -F'"' '{print $4}')
   var3d=$((var3dp*2))
   varfn=$(cat .badown2.tmp | grep href | grep document.getElementById | awk -F';' '{print $1}' | awk -F'"' '{print $4}')
   file_url=$(echo $var0 $var1 $((var2modulo + var3a + var3b + var3c + var3d + (5/5) )) $varfn | tr -d ' ')
   file_name=$(printf '%b' "$(echo $file_url | awk -F'/' '{gsub("%","\\x");gsub("+"," ");print $NF}')")
   rm .badown.tmp .badown2.tmp
   file_down $file_url "$file_name"
}
function zippyshare_old {
   wget -q -O .badown.tmp $1
   var0=$(echo $1 \
      | awk -F".com" '{print $1".com"}')
   var1=( $(cat .badown.tmp \
      | grep -B1 dlbutton \
      | grep href \
      | awk -F'"' '{for(i = 1; i <= NF; i++) {if ($i ~ /\//) {print $i}}}') )
   [ -z "$var1" ] &&  error "File does not exist here"
   var2=( $(cat .badown.tmp  \
      | grep dlbutton -B1 \
      | grep href \
      | grep + \
      | awk -F'(' '{print $3}'\
      | awk -F')' '{print $1}'))
   file_url=$(echo $var0 ${var1[0]} $((${var2[@]})) ${var1[1]} | tr -d ' ')
   file_name=$(printf '%b' "$(echo $file_url | awk -F'/' '{gsub("%","\\x");gsub("+"," ");print $NF}')")
   rm .badown.tmp
   file_down $file_url "$file_name"
}
function mediafire {
   file_url=$(wget -q -O- $1 \
      | grep  :\/\/download \
      | awk -F'"' '{print $2}')
   file_name=$(printf '%b' "$(echo $file_url \
      | awk -F'/' '{gsub("%","\\x");gsub("+"," ");print $NF}')")
   file_down $file_url "$file_name"
}
function switch {
   if [[ "$1" == *"mega"* ]]; then
      mega "$1"
   elif [[ "$1" == *"zippyshare"* ]]; then
      zippyshare "$1"
   elif [[ "$1" == *"mediafire"* ]]; then
      mediafire "$1"
   else
      showhelp; exit 1
   fi
}
function showhelp {
   echo -e "badown 0.4"
   echo -e "bash downloader for hostsites like mega, mediafire and zippyshare."
   echo -e "badown [OPTION] ['URL']"
   echo -e "\tOptions:"
   echo -e "\t-s,\t--speed SPEED         Download speed limit (integer values: 500B, 70K, 2M)."
   echo -e "\t-h,\t--help  	      Display this help."
   echo -e ""
   echo -e "if you find a bug, contact me @github -stck_lzm"
}
TEMP=$(getopt -o "s:h"  --long "speed:,help" -n badown -- "$@")
[ $? -eq 0 ] || {
echo "Incorrect options provided"
exit 1
}
eval set -- "$TEMP"
while true; do
   case "$1" in
      -s|--speed)		speed=" --limit-rate $2"; shift 2;;
      -h|--help)		showhelp; exit 1;;
      --)			shift; break;;
      **)			showhelp; exit 1;;
   esac
done
switch $1
