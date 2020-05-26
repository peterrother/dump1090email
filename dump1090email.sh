#!/bin/bash
#
# This script will process the dump1090 log files and notify via email whenever
# an aircraft was detected. This will reduce duplicates as much as possible to
# avoid getting spammed. If the data is all the same, it will ignore multiple
# hits based on track.
#
# Package requirements:
# - jq (https://stedolan.github.io/jq/)
#
# I use cron to run this every 3 mins on pi. Here is an example of the Crontab
# entry used:
#
# */3 * * * * /home/user/dump1090email/dump1090email.sh >> /home/user/dump1090email/dump1090email.log 2>&1
#
# Be sure to set the required configuration below before running this.
#
# Happy flight tracking!
#

# REQUIRED CONFIG! Make sure you update these before running
MY_RADAR="" # E.g. KJFK21
FROM_EMAIL="" # E.g. kfjk21@mydomain.com
TO_EMAIL="" # E.g. peter+localfr24@mydomain.com

# Less important configs
DUMP1090EMAIL_DIR=$HOME/dump1090email
PROCESSED_FILE=$DUMP1090EMAIL_DIR/dump1090email.processed
PROCESSED_FILE_MAX=1000
JSON_DIR=/run/dump1090-mutability

# Main processing
for f in `ls $JSON_DIR/history_*.json`
do
	FILE_NOW=`/usr/bin/jq '.now' $f```
	FILE_CONTENT=`sed $'s/[^[:print:]\t]//g' $f`

	AIRCRAFT_NUM=`/usr/bin/jq -c '.aircraft | length' <<< $FILE_CONTENT`

	LAST_AIRCRAFT=""
	for (( AIRCRAFT_IDX=0; AIRCRAFT_IDX < $AIRCRAFT_NUM; AIRCRAFT_IDX++ ))
	do
		CUR_AIRCRAFT=`/usr/bin/jq -c ".aircraft[$AIRCRAFT_IDX]" <<< $FILE_CONTENT`

		DATE=`date -d @$FILE_NOW`
		FLIGHT=`/usr/bin/jq '.flight' <<< $CUR_AIRCRAFT`
		FLIGHT=`echo $FLIGHT | /usr/bin/tr -d "[:space:]" | /usr/bin/tr -d '"'`
		HEX=`/usr/bin/jq '.hex' <<< $CUR_AIRCRAFT`
		HEX=`echo $HEX | /usr/bin/tr -d '"'`
		ALTITUDE=`/usr/bin/jq '.altitude' <<< $CUR_AIRCRAFT`
		VERT_RATE=`/usr/bin/jq '.vert_rate' <<< $CUR_AIRCRAFT`
		TRACK=`/usr/bin/jq '.track' <<< $CUR_AIRCRAFT`
		SPEED=`/usr/bin/jq '.speed' <<< $CUR_AIRCRAFT`
		SEEN=`/usr/bin/jq '.seen' <<< $CUR_AIRCRAFT`

		DUP_REDUCT="$FLIGHT~~$HEX~~$ALTITUDE~~$VERT_RATE~~$TRACK~~$SPEED"
		if grep -Fxq "$DUP_REDUCT" $PROCESSED_FILE; then
			continue
		fi

		LAST_AIRCRAFT="$FLIGHT~~$HEX~~$ALTITUDE~~$VERT_RATE~~$TRACK~~$SPEED"
		echo $LAST_AIRCRAFT >> $PROCESSED_FILE

		MSG="Timestamp: $DATE \nFlight: $FLIGHT \nHex Code: $HEX \nAltitude: $ALTITUDE ft\nVertical Speed: $VERT_RATE fpm\nTrack: $TRACK°\nGround Speed: $SPEED kts\n\nfr24://$FLIGHT\nhttp://flightradar24.com/$FLIGHT"
		`/usr/bin/mail -s "Aircraft Spotted" -aFrom:"$MY_RADAR 1090MHz Feed <$FROM_EMAIL>" $TO_EMAIL <<< $(echo -e "$MSG")`
	done
done

# Delete the oldest processed line (line 1) when we reach the max threshold
CUR_PROCESSED=`cat $PROCESSED_FILE | wc -l`
if (( $CUR_PROCESSED >= $PROCESSED_FILE_MAX )); then
	sed -i '1d' $PROCESSED_FILE
fi
