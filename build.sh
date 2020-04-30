#!/usr/bin/env bash
#
# Copyright (C) 2019 PixysOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#
# Superior ROM building script.


function exports() {
   export SUPERIOR_BUILD_PATH=/home/subins/superior/
   export SUPERIOR_OFFICIAL=true
   export KBUILD_BUILD_USER="sweeto"
   export KBUILD_BUILD_HOST="yui"
   export DJSON=$(curl -s https://raw.githubusercontent.com/SuperiorOS/official_devices/ten/devices.json)
   export DEVICE_MAINTAINERS=$(jq -r --arg DEVICE "$DEVICE" '.[] | select(.codename==$DEVICE) | .maintainer_name' <<< ${DJSON}) # The maintainer of that device
   if [ -z ${DEVICE_MAINTAINERS} ];
   then
      sendTG "${DEVICE} maintainer name not found probably device is not listed official (SuperiorOS)" 
      TGlogs "${DEVICE} maintainer name not found probably device is not listed official (SuperiorOS)" 
      exit 1
   fi
   export KBUILD_BUILD_USER=${DEVICE_MAINTAINERS}
}

function use_ccache() {
    # CCACHE UMMM!!! Cooks my builds fast
   if [ "$use_ccache" = "true" ];
   then
      printf "CCACHE is enabled for this build"
      export CCACHE_EXEC=$(which ccache)
      export USE_CCACHE=1
      export CCACHE_DIR=/home/subins/superior/ccache
      ccache -M 75G
    elif [ "$use_ccache" = "false" ];
    then
       export CCACHE_EXEC=$(which ccache)
       export CCACHE_DIR=/home/subins/superior/ccache
       ccache -C
       export USE_CCACHE=1
       ccache -M 50G
       wait
       printf "CCACHE Cleared"
    fi
}

function clean_up() {
  # Its Clean Time
   if [ "$make_clean" = "true" ]
   then
      make clean && make clobber
   elif [ "$make_clean" = "false" ]
   then
      rm -rf out/target/product/*
      wait
      echo -e "OUT dir from your repo deleted";
   fi
   # Clean old device dependencies
   if [ "$clean_device" = "true" ];
   then
      if [ -e /home/subins/superior/clone_path.txt ];
      then
         clone_path=$(cat /home/subins/superior/clone_path.txt)
         if [ -z ${clone_path} ];
         then
            echo "clone_path.txt is empty so nothing to wipe"
         else
            for WORD in `cat /home/subins/superior/clone_path.txt`
            do
              printf "${Blue}Deleting obsolete path /home/subins/superior/${WORD}\n${Color_Off}"
              rm -rf $WORD
            done
            rm -rf /home/subins/superior/clone_path.txt
            touch /home/subins/superior/clone_path.txt
         fi
    else
        echo "clone_path.txt doesnt exist"
        touch /home/subins/superior/clone_path.txt
    fi
    build_init
   fi
}

function build_init() {
    rm -rf /home/subins/superior/json/"${DEVICE}".json
    rm -rf /home/subins/superior/devices_dep.json
    wget -O /home/subins/superior/devices_dep.json -q https://raw.githubusercontent.com/SuperiorOS/jenkins/master/devices_dep.json
    jq --arg DEVICE "$DEVICE" '. | .[$DEVICE]' /home/subins/superior/devices_dep.json > /home/superior/source/json/"${DEVICE}".json
    export dep_count=$(jq length /home/subins/superior/json/${DEVICE}.json)
    printf "\n${UYellow}Cloning device specific dependencies \n\n${Color_Off}"
    for ((i=0;i<${dep_count};i++));
    do
       repo_url=$(jq -r --argjson i "$i" '.[$i].url' /home/subins/superior/json/${DEVICE}.json)
       branch=$(jq -r --argjson i "$i" '.[$i].branch' /home/subins/superior/json/${DEVICE}.json)
       target=$(jq -r --argjson i "$i" '.[$i].target_path' /home/subins/superior/json/${DEVICE}.json)
       printf "\n>>> ${Blue}Cloning to $target...\n${Color_Off}\n"
       git clone --recurse-submodules --depth=1 $repo_url -b $branch $target
       printf "${Color_Off}"
       if [ -e /home/subins/superior/$target ]
          then
             printf "\n${Green}Repo clone success...\n${Color_Off}"
             echo "$target" >> /home/subins/superior/clone_path.txt
           else
             sendTG "Could not clone some dependecies for [$DEVICE]($BUILD_URL) (SuperiorOS)"
	         TGlogs "Could not clone some dependecies for [$DEVICE]($BUILD_URL) (SuperiorOS)"
             printf "\n\n${Red}Repo clone fail...\n\n${Color_Off}"
             printf "${Cyan}Exiting${Color_Off}"
             sleep 5
             exit 1
            fi
    done
}

function build_main() {
    cd /home/subins/superior
    BUILD_START=$(date +"%s")
    source build/envsetup.sh
    lunch superior_${DEVICE}-userdebug
    printf "${BICyan}Starting build for ${DEVICE}${Color_Off}"
    TGlogs "Starting build for <a href=\"${BUILD_URL}\">${DEVICE}</a> on ${NODE_NAME} (SuperiorOS)"
    sendTG "Starting build for <a href=\"${BUILD_URL}\">${DEVICE}</a> on ${NODE_NAME} (SuperiorOS)"
    make bacon -j24
    BUILD_END=$(date +"%s")
    BUILD_TIME=$(date +"%Y%m%d-%T")
    DIFF=$((BUILD_END - BUILD_START))
}
   
	  
function build_end() {
   if [ -f /home/subins/superior/out/target/product/$DEVICE/SuperiorOS*.zip ]
   then
      cd /home/subins/superior/out/target/product/$DEVICE
      ZIP=$(ls SuperiorOS*.zip)
	  JSON="${DEVICE}.json"
	  status="passed"
	  build_json
          upload_ftp
          exit 0
   else
      status="failed"
	  upload_ftp
      exit 1
   fi
}

wget -O /home/subins/superior/extra.sh https://raw.githubusercontent.com/SuperiorOS/jenkins/master/extra.sh
source /home/subins/superior/extra.sh
DEVICE="$1" # Enter the codename of the device
use_ccache="$2" # Ccache time
clean_device="$3" # if the device is different from last one
make_clean="$4" # make a clean build or not 
upload="$5"

exports
use_ccache
clean_up
build_main
upload_ftp
build_end
