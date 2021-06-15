#!/bin/bash
SRCDIR="/home/<username>/Documents/my_work/"
DESTDIR="/home/<username>/Backups/"
FILENAME=ug-$(date +%-Y%-m%-d)-$(date +%-T).tgz
tar --create --gzip --file=$DESTDIR$FILENAME $SRCDIR