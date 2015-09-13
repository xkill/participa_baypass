#!/bin/bash

set -x

if [ $# -lt 3 ]
then
    echo "Usage $0 <number of accounts> <base email> <base username>"
    echo "Example: $0 5 lala@gmail.com lala"
    echo "	create and validate accounts lala1 lala2 ... lala5"
    exit 1
fi

TOTAL=$1
BASEMAIL=$2
BASENAME=$3
BASEURL=$4


rm -vf  cookie.jar output.html salida.html tesseract-tmp.txt test.jpg


for NUM in `seq 1 $TOTAL`
do

TOKEN=""

# Get Cookies and tokens
curl -s -k -c cookie.jar -X 'GET' -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:40.0) Gecko/20100101 Firefox/40.0' $BASEURL/users/sign_up > output.html

TOKEN=`cat output.html | grep -oP 'authenticity_token"\s*value=".*?"' | awk -F'"' '{print $3}'`
CAPTCHA_IMG_CODE=`cat output.html | grep -oP 'simple_captcha\?code=[a-z0-9]+' | awk -F'=' '{print $2}'`
CAPTCHA_IMG_URI=$BASEURL`cat output.html | grep -oP '/simple_captcha\?code=.*?"' | sed 's/"$//'`

# Get CAPTCHA IMG
curl -s -k -b cookie.jar -X -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:40.0) Gecko/20100101 Firefox/40.0' -X 'GET' ${CAPTCHA_IMG_URI} > test.jpg

# Resolve CAPTCHA
tesseract test.jpg tesseract-tmp -psm 8 -c tessedit_char_whitelist=ABCDEFGHIJKLMNOPQRSTUVXYZ
CAPTCHA=`head -n1 tesseract-tmp.txt`

# Register account
curl -i -s -k  -X 'POST' \
    -H 'User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:40.0) Gecko/20100101 Firefox/40.0' -H 'DNT: 1' -H "Referer: $BASEURL/users" -H 'Content-Type: application/x-www-form-urlencoded' \
	-b cookie.jar \
    --data-binary $'utf8=%E2%9C%93&authenticity_token='$TOKEN$'&user%5Busername%5D='$BASENAME$NUM$'&user%5Bemail%5D='$BASEMAIL$'%2B'$NUM$'%40gmail.com&user%5Bpassword%5D='$BASENAME$NUM$BASEMAIL$'&&user%5Bpassword_confirmation%5D='$BASENAME$NUM$BASEMAIL$'&user%5Bcaptcha%5D='$CAPTCHA$'&user%5Bcaptcha_key%5D='$CAPTCHA_IMG_CODE$'&user%5Bterms_of_service%5D=0&user%5Bterms_of_service%5D=1&commit=Registrarse' \
    "$BASEURL/users" > salida.html

if `grep -q ^30 salida.html`
then
	echo "Acc $BASENAME$NUM Mail $BASEMAIL%2B$NUM%40gmail.com $BASENAME$NUM$BASEMAIL -> Created"
fi

done
