#!/bin/bash

DateStart=20051226
DateEnd=20170503

d=$DateStart

echo "Scraping alterslash..."
while [ "$d" != $DateEnd ]; do 
	echo $d
	wget -qO- "http://alterslash.org/day/$d" | grep 'href="#article' | awk '{gsub("<[^>]*>", "");gsub(/^[ \t]+/, "")}1' >./archive/$d 2>/dev/null
	d=$(date -d "$d + 1 day" +%Y%m%d)
done

echo "Preparing database in csv format..."
rm -f slashdot.db
echo "Date,Article" > slashdot.db
rm -rf ./alterslash_dump && mkdir ./alterslash_dump
pushd ./alterslash_dump >/dev/null
for f in 2*[0-9]; do
	awk '{print FILENAME "," $0}' $f >> ../slashdot.db
done
popd >/dev/null
rm -rf ./alterslash_dump
