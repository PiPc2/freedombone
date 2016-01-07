#!/bin/bash

lang=$1
dest_dir=$2

if [ ! $lang ]; then
	lang='EN'
fi
if [ ! $2 ]; then
	echo 'Specify language and destination directory'
	exit 1
fi

if [ ! -d $dest_dir ]; then
	mkdir -p $dest_dir
fi
if [ ! -d $dest_dir/images ]; then
	mkdir $dest_dir/images
fi

cp -r $lang/* $dest_dir
cp *.css $dest_dir
cp -r ../img/* $dest_dir/images
chown -R www-data:www-data $dest_dir

echo "Website deployed to $dest_dir"
exit 0
