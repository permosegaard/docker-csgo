#!/bin/bash

ip route change default via 172.17.42.254
if [ -z "${STEAM_USER}" ]; then STEAM_CREDENTIALS="anonymous"; else STEAM_CREDENTIALS="${STEAM_USERNAME} ${STEAM_PASSWORD}"; fi

# start seed update section
# shell in and rsync /server/* and /root/{Steam,steamcmd}/* to host /seed/$type/{game,steam,steamcmd}
curl -s "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar -vzx -C "/root/steamcmd/"
/root/steamcmd/steamcmd.sh +login $STEAM_CREDENTIALS +force_install_dir /server +app_update 740 +quit
apt-get update && apt-get install -y rsync openssh-client && echo && echo "update complete, pausing..." && read && exit
# end seed update section

if [ "$( find /server/ -type f | wc -l )" -lt "1" ]
then
  echo "copying seed across... this may take some time depending on the game size"
  rm -Rf /server/* /root/Steam/* /root/steamcmd/*
  cp -Rfs /seed/${CONTAINER_TYPE}/game/* /server/
  cp -Rfs /seed/${CONTAINER_TYPE}/steamcmd/* /root/steamcmd/
  cp -Rfs /seed/${CONTAINER_TYPE}/steam/* /root/Steam/
  cp -f /seed/misc/libksm_preload.so /server/
fi

root/steamcmd/steamcmd.sh +login $STEAM_CREDENTIALS +force_install_dir /server +app_update 740 +quit

settings_array=(
	"sv_setsteamaccount 9D09591118D61C35234F32F5BBD79575"
	"game_type 0"
	"game_mode 0"
	"mapgroup mg_active"
	"map de_dust2"
)
settings_string="$( printf " +%s" "${settings_array[@]}" )"

ulimit -n 2048 && cd /server/ && LD_PRELOAD=/server/libksm_preload.so ./srcds_run -game csgo -console -usercon -port ${PORT_27015} ${settings_string}
