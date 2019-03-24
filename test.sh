#!/bin/bash

source SECRETS
REAL=`dig SOA +short o. @51.75.173.177 | egrep -ho '[0-9]{10}'`
DATE=`date`

wget -qO api.txt --no-check-certificate "https://api.opennic.glue/acl/bind/?user=${USER}&auth=${AUTH}"
sed -n '/opennic_whitelist/q;p' api.txt > api2.txt #remove all non-DNS servers!
cat api2.txt | grep -P '^\t' > api3.txt
cut -f2 api3.txt | sed 's/.$//' > api4.txt
grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' api4.txt > api5.txt #can't test IPv6 currently
awk '!a[$0]++' api5.txt > api6.txt

rm index.html
cat head.layout >> index.html
echo "<p>The current serial for the .o zone is: <span class=\"green\">$REAL</span></p>" >> index.html
echo "<p>This page was last updated on $DATE</p>" >> index.html
cat table.layout >> index.html

while read ip; do
  echo "<tr>" >> index.html
  echo "  <td>$ip</td>" >> index.html
  SOA=`dig +short +time=2 +tries=1 SOA @$ip o. | egrep -ho '[0-9]{10}'`
  if [ "$SOA" == "$REAL" ]; then
    echo "  <td class=\"green\">Ok! $SOA</td>" >> index.html
  else
    echo "  <td class=\"red\">Bad! $SOA</td>" >> index.html
  fi
  echo "</tr>" >> index.html
done <api6.txt

echo "</table>" >> index.html
NEW_DATE=`date`
echo "<p>Finished testing at $NEW_DATE</p>" >> index.html
cat foot.layout >> index.html
mv index.html public/index.html
rm api*.txt
