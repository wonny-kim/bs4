#!/bin/bash
USERID=laravel

if [ "`grep ${USERID} /etc/passwd`" == "" ];then
echo "aa";
else
echo "bb";
fi
