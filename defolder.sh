#!/bin/bash
WORKDIR='./'
DESTDIR=$WORKDIR

#Parsing arguments and setting up paths
if [ $# -eq 0 ]; then
    echo "script usage: ./defolder.sh '/working/dir/' 'destination/dir/'"
    echo "if second argument is blank /working/dir is the destination/dir/"
    exit
elif [ $# -eq 1 ]; then
    if [ ! -d "$1" ]; then
        echo "error! working directory doesnt exist"
        exit
    fi
    WORKDIR=$1
elif [ $# -eq 2 ]; then
    WORKDIR=$1
    DESTDIR=$2
fi

#Create destination directory if it doesnt exist
if [ ! -d "$DESTDIR" ]; then
    echo "Destination doesn't exist. Creating directory..."
    mkdir $DESTDIR
fi

for DIR in "$WORKDIR"/*/
do
    for FILE in "$DIR"/*
    do
        echo "copying $FILE"
        cp -r "$FILE" "$DESTDIR"
        echo "complete!"
    done
done

