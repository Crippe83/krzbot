#!/bin/bash

############################################################################
# I got these from my PMSF installation, handy!
# I guess if you dont have them you should probably get them
#  https://github.com/whitewillem/PMSF/tree/master/static/data/
movesfile=/var/www/html/static/data/moves.json
monsfile=/var/www/html/static/data/pokemon.json
# This is the name of my database
mondb=mydatabase
# DB format. Only valid options: monocle / rm
dbtype=monocle
# Go to https://developer.mapquest.com/ and make a free account, then put the API key here
keys=(xxxxxxxxxxxxxxx)
# or multiple accounts! we'll choose them randomly!
#keys=(xxxxxxxxxxxxxxx xxxxxxxxxxxxxxx xxxxxxxxxxxxxxx)

# zoom level for map, I like 14
zoom=14
############################################################################
###                           Requirements:                              ###
############################################################################
# you need bash, bc, and httpie (https://httpie.org/).                     #
# you may need to modify the query in query() right below.                 #
# You will need to setup webhooks in discord and then set those up below.  #
# If you want a map you need to make an API key and fill it in above.      #
# Remember to remove the x from xhttps.                                    #
# Install the database schema before you use it.                           #
# You can decide how and when to run it, i like to use crontab:            #
# * * * * * /home/pi/runbot.sh                                             #
# after you edit runbot.sh and change the directory in the crontab line    #
# and runbot.sh script.                                                    #
# This would make it run every minute if it is not already running.        #
############################################################################
##############Happy hunting###############krzthehunter######################
############################################################################
# I take no responsibility for any harm caused by this script including    #
# injured cats or nuclear hollocaust. Use it at your own risk. In fact you #
# really should only use this if you understand it because you need to     #
# know a little bash to configure conditions for when to send to webhooks. #
# This is released under a custom license im calling the NOSUPPORT license #
# Basically, do whatever you want with it, just dont ask me to support it! #
# Sorry, I didn't figure out an easy way to abstract the config so normal  #
# non unix admin users could configure it. I just wrote it as a quick      #
# solution for myself, but I figured why not share with you guys too.      #
# Oh and FYI the bot will leak your mapquest key... the only way around    #
# that would be to download the image and then attach it to every post.    #
############################################################################

query(){
mysql -NB "$1" -e "$2"
}
randomkey(){
echo ${keys[$(echo "$RANDOM$RANDOM % ${#keys[@]}"|bc)]}
}
pokelevel=(NULL 0.094 0.166398 0.215732 0.25572 0.29025 0.321088 0.349213 0.375236 0.399567 0.4225 0.443108 0.462798 0.481685 0.499858 0.517394 0.534354 0.550793 0.566755 0.582279 0.5974 0.612157 0.626567 0.640653 0.654436 0.667934 0.681165 0.694144 0.706884 0.719399 0.7317 0.737769 0.743789 0.749761 0.755686 0.761564)
getlevel(){
for i in ${!pokelevel[@]} ;do
 [[ "${pokelevel[$i]}" == "$cpm" ]] && lvl="$i" && [[ "$cpm" == NULL ]] && lvl="?"
done
}
isditto(){
if (( "$weathers" > 0 ));then
 if (( "$attack" < 4 )) || (( "$defense" < 4 )) || (( "$stamina" < 4 )) || (( "$lvl" < 6 )) ;then
  return 0
 fi
fi
return 1
}
monbody(){
cat << "EOF"
{
  "embeds": [{
    "title": "Map to MONNAME",
    "url": "xhttp://maps.google.com/maps?q=LAT,LON",
    "description": "Available until: TIMER (COUNTER)",
    "thumbnail": {
      "url": "xhttps://raw.githubusercontent.com/whitewillem/PogoAssets/resized/icons_large/pokemon_icon_MONNUM_FORM.png"
    },
    "fields": [
      {
        "name": "**Mon**",
        "value": "MONNAME WEATHER",
        "inline": true
      },
      {
        "name": "**L30+ stats**",
        "value": "IVs: ATTACKA/DEFENSED/STAMINAS (PCT%) \nCP: CPVAL (lvl LEVEL) \nMoveset: MOVE1 - MOVE2 \nGender: GENDER",
        "inline": true
      }
    ],
    "image": {
      "url": "xhttps://open.mapquestapi.com/staticmap/v4/getmap?key=KEY&size=400,400&type=map&imagetype=png&center=LAT,LON&pois=MON,LAT,LON&zoom=ZOOM"
    },
    "timestamp": "TIMESTAMP"
  }]
}
EOF
}
sendmonmsg(){
http --output /dev/null "$url" < <(sed -e "s,MONNAME,$monname,g" -e "s,LAT,$lat,g" -e "s,LON,$lon,g" -e "s,TIMER,$time," -e "s,COUNTER,$counter," -e "s,MONNUM,$monnum," \
-e "s,FORM,$form," -e "s,WEATHER,$weather," -e "s,ATTACK,$attack," -e "s,DEFENSE,$defense," -e "s,STAMINA,$stamina," -e "s,PCT,$percent," \
-e "s,CPVAL,$cp," -e "s,LEVEL,$lvl," -e "s,MOVE1,$move1," -e "s,MOVE2,$move2," -e "s,GENDER,$gender," -e "s,TIMESTAMP,$timestamp," -e "s,KEY,$key," \
-e "s,ZOOM,$zoom," <(monbody))
}
chkgf(){
 python3 chkgeofence.py -i "$1" -lat "$lat" -lon "$lon" && sendmonmsg
}
raidbody(){
cat << "EOF"
{
  "embeds": [{
    "title": "TITLE (LEVEL)",
    "url": "xhttp://maps.google.com/maps?q=LAT,LON",
    "description": "**TIMER (COUNTER)**",
    "thumbnail": {
      "url": "MONURL"
    },
    "fields": [
      {
        "name": "**Gym Name:** GYMNAME",
        "value": "**Gym Owners:** TEAM",
        "inline": false
      }
    ],
    "image": {
      "url": "xhttps://open.mapquestapi.com/staticmap/v4/getmap?key=KEY&size=400,400&type=map&imagetype=png&center=LAT,LON&pois=GYM,LAT,LON&zoom=ZOOM"
    },
    "timestamp": "TIMESTAMP"
  }]
}
EOF
}
sendraidmsg(){
http --output /dev/null "$url" < <(sed -e "s,TITLE,$title," -e "s,LAT,$lat,g" -e "s,LON,$lon,g" -e "s,COUNTER,$counter," -e "s,TIMER,$timer," \
-e "s,MONURL,$raidmonurl," -e "s,GYMNAME,$gymname," -e "s,LEVEL,$level," -e "s,TIMESTAMP,$timestamp," -e "s,KEY,$key," -e "s,ZOOM,$zoom," \
-e "s,TEAM,$teamname," <(raidbody))
}
scanmons(){
while read -r monid expire encounter lat lon attack defense stamina moveid1 moveid2 gender forms cp cpm weathers ;do
[[ "$attack" != NULL ]] && encounter="${encounter}a${attack}d${defense}s${stamina}" iv=1 || iv=0
[[ $(query krzbot "select expire from pokemon where monkey='$encounter'") ]] && continue
query krzbot "insert into pokemon set monkey=\"$encounter\", expire=$expire;"
case "$dbtype" in
 monocle) lvl="$cpm" ;;
 rm) getlevel ;;
esac
monname=$(grep -A1 \"$monid\" "$monsfile" |awk -F'"' '/name/{print $4}')
time=$(date -d @"$expire" +%T)
secs=$(($expire - $(date +%s)))
min=$(( secs / 60))
sec=$(( secs % 60))
counter="${min}m${sec}s"
case "$monid" in
 [0-9]) monnum="00$monid" ;;
 [0-9][0-9]) monnum="0$monid" ;;
 [0-9][0-9][0-9]) monnum="$monid" ;;
esac
case "$forms" in
 [0-9]) form="0$forms" ;;
 [0-9][0-9]) form="$forms" ;;
esac
case "$weathers" in             #POGOProtos/Enums/WeatherCondition.proto
 0) weather="" ;;                #NONE
 1) weather=":sunny:" ;;         #CLEAR
 2) weather=":cloud_rain:" ;;    #RAINY
 3) weather=":partly_sunny:" ;;  #PARTLY_CLOUDY
 4) weather=":cloud:" ;;         #OVERCAST
 5) weather=":cloud_tornado:" ;; #WINDY
 6) weather=":snowman:" ;;       #SNOW
 7) weather=":fog:" ;;           #FOG
esac
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S')
key=$(randomkey)
if (( "$iv" )) ;then
 percent=$(echo "($attack+$defense+$stamina)/.45"|bc)
 move1=$(grep -A1 \"$moveid1\" "$movesfile" |tail -n1|awk -F'"' '{print $4}')
 move2=$(grep -A1 \"$moveid2\" "$movesfile" |tail -n1|awk -F'"' '{print $4}')
 case "$gender" in
  1)gender=":man:" ;;
  2)gender=":woman:" ;;
 esac
(( $percent > 81 ))   && (( $lvl > 32 ))  && url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg
(( $percent > 89 ))   && (( $lvl == 35 )) && url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg
(( $percent == 100 )) && (( $lvl == 35 )) && url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg
(( $percent == 0 ))   && url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg
(( $percent == 100 )) && url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg
(( $lvl == 35 ))       && url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg
# send if inside a specific geofence. Don't use this for all mons it will slow you down. thanks cookie!
(( $percent == 100 )) && url="xhttps://discordapp.com/api/webhooks/" && chkgf "/path/to/geofence.txt"
else
 attack="?" defense="?" stamina="?" percent="?" move1="?" move2="?" gender="?" lvl="?" cp="?"
fi
case "$monid" in
 46|48|163|165|193|223|293|316) isditto && url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg ;; # ditto
 65)  url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # alakazam
 348) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # armaldo
 371|372|373) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg ;; # bagon
 374|375|376) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg ;; # beldum
 242) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # blissey
 436|437) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg     ;; # bronzor
 113) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # chansey
 6) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg           ;; # charizard
 408|409) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg     ;; # cranidos
 410|411) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg     ;; # shieldon
 453|454) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg     ;; # croagunk
 149) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # dragonite
 134|135|136|196|197) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg ;; # eeveelutions
 349) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # feebas
 456|457) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg     ;; # finneon
 94) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg          ;; # gengar
 76) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg          ;; # golem
 297) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # hariyama
 115|122|128|130|208|212|272|289|295|306|324|350|369|439) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg  ;; # just in case
 131) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # lapras
 246|247) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg     ;; # larvitar
 270|271|272) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg ;; # lotad
 68) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg          ;; # machamp
 280|281|282|475) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg ;; #ralts
 451|452) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg     ;; # skorupi
 143) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # snorlax
 328) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # trapinch
 248) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # tyranitar
 201) url="xhttps://discordapp.com/api/webhooks/" && sendmonmsg         ;; # unown
esac
done < <(query "$mondb" "$monquery")
}
scanraids(){
while IFS=';' read -r eid gymname lat lon park team lvl bossid bosscp moveid1 moveid2 forms raidstart expire ;do
[[ $(query krzbot "select expire from raids where raidkey='${eid}${bossid}'") ]] && continue
query krzbot "insert into raids set raidkey=\"${eid}${bossid}\", expire=$expire;"
if [[ "$bossid" == NULL ]] ;then
 title="raid"
 level="lvl $lvl"
 case "$lvl" in
    5) egg="legendary" ;;
  3|4) egg="rare" ;;
  1|2) egg="normal" ;;
 esac
 raidmonurl="xhttps://raw.githubusercontent.com/whitewillem/PogoAssets/master/static_assets/png/ic_raid_egg_${egg}.png"
 time=$(date -d @"$raidstart" +%T)
 secs=$(($raidstart - $(date +%s)))
 timer="Raid will start at: $time"
 unset extra
else
 monname=$(grep -A1 \"$bossid\" "$monsfile" |awk -F'"' '/name/{print $4}')
 move1=$(grep -A1 \"$moveid1\" "$movesfile" |tail -n1|awk -F'"' '{print $4}')
 move2=$(grep -A1 \"$moveid2\" "$movesfile" |tail -n1|awk -F'"' '{print $4}')
 extra="\\\n**CP:** $bosscp \\\n**Moveset:** ${move1} - ${move2}"
 title="$monname raid"
 level="lvl $lvl"
 case "$monid" in
  [0-9]) monnum="00$monid" ;;
  [0-9][0-9]) monnum="0$monid" ;;
  [0-9][0-9][0-9]) monnum="$monid" ;;
 esac
 case "$forms" in
  [0-9]) form="0$forms" ;;
  [0-9][0-9]) form="$forms" ;;
 esac
 raidmonurl="xhttps://raw.githubusercontent.com/whitewillem/PogoAssets/resized/icons_large/pokemon_icon_${bossid}_${form}.png"
 time=$(date -d @"$expire" +%T)
 secs=$(($expire - $(date +%s)))
 timer="Available until: $time"
fi
case "${team}" in
 0) teamname="Unclaimed ${extra}" ;;
 1) teamname="Mystic :blue_heart: ${extra}" ;;
 2) teamname="Valor :red_circle: ${extra}" ;;
 3) teamname="Instinct :yellow_heart: ${extra}" ;;
esac
min=$(( secs / 60))
sec=$(( secs % 60))
counter="${min}m ${sec}s"
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S')
key=$(randomkey)
case "$eid" in #i choose to use forts.external_id
 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xx) url="xhttps://discordapp.com/api/webhooks/" && sendraidmsg ;;
 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xx|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.xx) url="xhttps://discordapp.com/api/webhooks/" && sendraidmsg ;;
esac
case "$bossid" in
 248) url="xhttps://discordapp.com/api/webhooks/" && sendraidmsg ;; # tyranitar
esac
case "$lvl" in
 5) url="xhttps://discordapp.com/api/webhooks/" && sendraidmsg ;; # Level5
esac
done < <(query "$mondb" "$raidquery"|sed 's/\x09/;/g')
}

if ! query krzbot "select true" >/dev/null 2>&1 ;then
 echo "Database schema not installed."
 exit 1
fi
query krzbot "delete from pokemon where expire < unix_timestamp(DATE_ADD(SYSDATE(), INTERVAL -1 HOUR));"
query krzbot "delete from raids where expire < unix_timestamp(DATE_ADD(SYSDATE(), INTERVAL -1 HOUR));"
case "$dbtype" in
 monocle) monquery="select pokemon_id, expire_timestamp, encounter_id, lat, lon, atk_iv, def_iv, sta_iv, move_1, move_2, gender, form, cp, level, weather_boosted_condition from sightings where expire_timestamp > unix_timestamp();"
          raidquery="select forts.external_id, name, lat, lon, park, team, level, pokemon_id, cp, move_1, move_2, form, time_battle, time_end from forts join raids on raids.fort_id=forts.id join fort_sightings on fort_sightings.fort_id=forts.id where time_end > unix_timestamp();"
       ;;
      rm) monquery="SET time_zone = '+00:00' ;select pokemon_id, unix_timestamp(disappear_time), encounter_id, latitude, longitude, individual_attack, individual_defense, individual_stamina, move_1, move_2, gender, form, cp, cp_multiplier, weather_boosted_condition from pokemon where disappear_time > utc_timestamp() and concat(encounter_id, 'a', individual_attack, 'd', individual_defense, 's', individual_stamina) not in (select monkey from krzbot.pokemon);"
          raidquery="SET time_zone = '+00:00' ;select raid.gym_id, name, latitude, longitude, park, team_id, level, pokemon_id, cp, move_1, move_2, raid.form, unix_timestamp(start), unix_timestamp(end) from raid join gym on raid.gym_id=gym.gym_id join gymdetails on raid.gym_id=gymdetails.gym_id where end > utc_timestamp();"
       ;;
       *) echo "dbtype is set to $dbtype but the only valid options are monocle or rm. Fix this before trying to continue" && exit ;;
esac
scanmons
scanraids

