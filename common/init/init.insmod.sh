#! /vendor/bin/sh

#########################################
### cfg file format:                  ###
### --------------------------------- ###
### [insmod|setprop] [path|prop name] ###
### ...                               ###
#########################################

cfg_file=$1

if [ -f $cfg_file ]; then
  while IFS=" " read -r action name value arg1 arg2 arg3 arg4 arg5 arg6 arg7 arg8 arg9
  do
    case $action in
      "insmod") insmod $name $value $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 ;;
      "setprop") setprop $name $value ;;
      "modprobe")
                 if [ -f /system/lib/modules/modules.load ]; then
                     arg="$(ls /system/lib/modules/)"
                     modprobe -a -d /system/lib/modules/ $arg
                 fi
                 if [ -f  /vendor/lib/modules/modules.load ]; then
                     arg="$(cat /vendor/lib/modules/modules.load)"
                     modprobe -a -d /vendor/lib/modules $arg
                 fi
    esac
  done < $cfg_file
fi

# set property even if there is no insmod config
# as property value "1" is expected in early-boot trigger
setprop $2 1
