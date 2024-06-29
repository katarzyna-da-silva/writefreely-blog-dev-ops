#!/bin/bash

echo "start"

export MYSQL_HOST=${MYSQL_HOST: -mydbhost}

apachectl start

echo "Starting WriteFreely"
if [ -x /app/writefreely/writefreely ]; then
    /app/writefreely/writefreely
else
    echo "/app/writefreely/writefreely is not executable or does not exist"
    exit 1
fi


