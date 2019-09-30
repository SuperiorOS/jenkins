#!/usr/bin/env bash
#
# Copyright (C) 2019 SuperiorOS project.
#
# Licensed under the General Public License.
# This program is free software; you can redistribute it and/or modify
# in the hope that it will be useful, but WITHOUT ANY WARRANTY;
#
#
# SuperiorOS ROM Uploading Script.

command="$1"

if [ "$command" == "Push to FTP" ];
then
         echo "http://downloads.pixysos.com/.superior/${DEVICE}/${ZIP}" > "${msg}"
         deldog "${msg}"
	 DL_LINK="${DEL_NORM}"
         echo -e "Uploading test build ${ZIP}"
         sshc "rm -rf /home/ftp/uploads/.superior/${DEVICE}"
         sshc "mkdir -p /home/ftp/uploads/.superior/${DEVICE}"
         scpc "${ZIP}"
         scpc "${JSON}"
      echo -e "Test Build Pushed to FTP..."
fi

if [ "$command" == "Push to Sourceforge" ];
then
         cd ~
         cd superior/out/target/product/${DEVICE}
         sftp darkstar085@frs.sourceforge.net
         cd /home/frs/project/superioros/${DEVICE}
         put Superior*.zip
         echo -e "Build Uploaded succesfully..."
fi
