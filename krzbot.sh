#!/bin/bash

############################################################################
# I got these from my PMSF installation, handy!
# I guess if you dont have them you should probably get them
#  https://github.com/whitewillem/PMSF/tree/master/static/data/
movesfile=/var/www/html/static/data/moves.json
monsfile=/var/www/html/static/data/pokemon.json
# This is the name of my Monocle formatted database
mondb=new
# Go to https://developer.mapquest.com/ and make a free account, then put the API key here
key="xxxxxxxxxxxxxxx"
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
makedb(){
cat << "EOF"
create database krzbot;
use krzbot;
create table `pokemon` (
`monkey` varchar(64) NOT NULL, -- you know, like mon-key :D
`expire` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
alter table `pokemon`
 add primary key (`monkey`);
EOF
}
body(){
cat << "EOF"
{
  "embeds": [{
    "title": "Map to MONNAME",
    "url": "http://maps.google.com/maps?q=LAT,LON",
    "description": "Available until: TIMER (COUNTER)",
    "thumbnail": {
      "url": "https://raw.githubusercontent.com/whitewillem/PogoAssets/resized/icons_large/pokemon_icon_MONNUM_FORM.png"
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
sendmsg(){
http "$url" < <(sed -e "s,MONNAME,$monname,g" -e "s,LAT,$lat," -e "s,LON,$lon," -e "s,TIMER,$time," -e "s,COUNTER,$counter," -e "s,MONNUM,$monnum," \
-e "s,FORM,$form," -e "s,WEATHER,$weather," -e "s,ATTACK,$attack," -e "s,DEFENSE,$defense," -e "s,STAMINA,$stamina," -e "s,PCT,$percent," \
-e "s,CPVAL,$cp," -e "s,LEVEL,$lvl," -e "s,MOVE1,$move1," -e "s,MOVE2,$move2," -e "s,GENDER,$gender," -e "s,TIMESTAMP,$timestamp," -e "s,KEY,$key," \
-e "s,LAT,$lat,g" -e "s,LON,$lon,g" -e "s,ZOOM,$zoom," <(body))
}
query krzbot "select true" >/dev/null 2>&1 || mysql < <( makedb )
query krzbot "delete from pokemon where expire < unix_timestamp(DATE_ADD(SYSDATE(), INTERVAL -1 HOUR));"
while read -r monid expire encounter lat lon attack defense stamina moveid1 moveid2 gender forms cp lvl weathers ;do
[[ "$attack" != NULL ]] && encounter="${encounter}a${attack}d${defense}s${stamina}" iv=1 || iv=0
[[ $(query krzbot "select expire from pokemon where monkey='$encounter'") ]] && continue
query krzbot "insert into pokemon set monkey=\"$encounter\", expire=$expire;"
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
if (( "$iv" )) ;then
 percent=$(echo "($attack+$defense+$stamina)/.45"|bc)
 move1=$(grep -A1 \"$moveid1\" "$movesfile" |tail -n1|awk -F'"' '{print $4}')
 move2=$(grep -A1 \"$moveid2\" "$movesfile" |tail -n1|awk -F'"' '{print $4}')
 case "$gender" in
  1)gender=":man:" ;;
  2)gender=":woman:" ;;
 esac
(( $percent > 81 ))   && (( $lvl > 32 ))  && url="xhttps://discordapp.com/api/webhooks/" && sendmsg
(( $percent > 89 ))   && (( $lvl == 35 )) && url="xhttps://discordapp.com/api/webhooks/" && sendmsg
(( $percent == 100 )) && (( $lvl == 35 )) && url="xhttps://discordapp.com/api/webhooks/" && sendmsg
(( $percent == 0 ))   && url="xhttps://discordapp.com/api/webhooks/" && sendmsg
(( $percent == 100 )) && url="xhttps://discordapp.com/api/webhooks/" && sendmsg
(( $lvl == 35 ))      && url="xhttps://discordapp.com/api/webhooks/" && sendmsg
else
 attack="?" defense="?" stamina="?" percent="?" move1="?" move2="?" gender="?" lvl="?" cp="?"
fi
case "$monid" in
 65)  url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # alakazam
 348) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # armaldo
 371|372|373) url="xhttps://discordapp.com/api/webhooks/" && sendmsg ;; # bagon
 374|375|376) url="xhttps://discordapp.com/api/webhooks/" && sendmsg ;; # beldum
 242) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # blissey
 436|437) url="xhttps://discordapp.com/api/webhooks/" && sendmsg     ;; # bronzor
 113) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # chansey
 6) url="xhttps://discordapp.com/api/webhooks/" && sendmsg           ;; # charizard
 408|409) url="xhttps://discordapp.com/api/webhooks/" && sendmsg     ;; # cranidos
 410|411) url="xhttps://discordapp.com/api/webhooks/" && sendmsg     ;; # shieldon
 453|454) url="xhttps://discordapp.com/api/webhooks/" && sendmsg     ;; # croagunk
 149) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # dragonite
 134|135|136|196|197) url="xhttps://discordapp.com/api/webhooks/" && sendmsg ;; # eeveelutions
 349) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # feebas
 456|457) url="xhttps://discordapp.com/api/webhooks/" && sendmsg     ;; # finneon
 94) url="xhttps://discordapp.com/api/webhooks/" && sendmsg          ;; # gengar
 76) url="xhttps://discordapp.com/api/webhooks/" && sendmsg          ;; # golem
 297) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # hariyama
 131) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # lapras
 246|247) url="xhttps://discordapp.com/api/webhooks/" && sendmsg     ;; # larvitar
 270|271|272) url="xhttps://discordapp.com/api/webhooks/" && sendmsg ;; # lotad
 68) url="xhttps://discordapp.com/api/webhooks/" && sendmsg          ;; # machamp
 280|281|282|475) url="xhttps://discordapp.com/api/webhooks/" && sendmsg ;; #ralts
 451|452) url="xhttps://discordapp.com/api/webhooks/" && sendmsg     ;; # skorupi
 143) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # snorlax
 328) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # trapinch
 248) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # tyranitar
 201) url="xhttps://discordapp.com/api/webhooks/" && sendmsg         ;; # unown
esac
done < <(query "$mondb" "select pokemon_id, expire_timestamp, encounter_id, lat, lon, atk_iv, def_iv, sta_iv, move_1, move_2, gender, form, cp, level, weather_boosted_condition from sightings where expire_timestamp > unix_timestamp();")
