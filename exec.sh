#!/bin/bash

if [ -z "$1" ]; then
    echo "parameter is empty, specify a file to conduct lexical analysis."
    exit 1
fi

cat $1
