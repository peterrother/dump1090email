Dump1090Email README
===

Dump1090 Email is a simple bash script that can be used to deliver email updates every time an aircraft is detected via dump1090.

This script will process the dump1090 log files and notify via email whenever an aircraft was detected. This will reduce duplicates as much as possible to avoid getting spammed. If the data is all the same, it will ignore multiple hits based on track.

Package requirements
---
* jq (https://stedolan.github.io/jq/)

Installation
---
Set the required configuration variables and run the file. Cron can be used for automated tracking around the clock. Here is an example Crontab entry that runs the script every 3 minutes:

```
*/3 * * * * /home/user/dump1090email/dump1090email.sh >> /home/user/dump1090email/dump1090email.log 2>&1
```

Happy flight tracking!
