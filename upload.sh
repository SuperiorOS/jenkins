#!/usr/bin/env bash
#
# Copyright (C) 2019-2020 SuperiorOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#

DEVICE=${1}
FILENAME=${2}

export spass bottoken

function TG() {
    curl -s "https://api.telegram.org/bot${bottoken}/sendmessage" --data "text=${*}&chat_id=-1001342674978&parse_mode=HTML" > /dev/null
}

function mirror() {
   echo "$FILENAME"
   cp /home/ftp/uploads/.superior/"${DEVICE}"/"${FILENAME}" /home/ftp/ft-uploads/
   CHECK=$(ls SuperiorOS*.zip)
   [ "${CHECK}" == "${FILENAME}" ] && echo "${FILENAME} found, Starting upload process" || TG "$FILENAME cannot be downloaded correctly"
   sshpass -p "${spass}" scp -o StrictHostKeyChecking=no "${FILENAME}" darkstar085@frs.sourceforge.net:/home/frs/project/superioros/"${DEVICE}"/
   TG "${FILENAME} has been uploaded to <a href=\"https://downloads.sourceforge.net/project/superioros/${DEVICE}/${FILENAME}\">Sourceforge</a>"
   rm -rf *.zip
}

mirror