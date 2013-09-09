#!/usr/bin/env bash
sed 's/wells=//g;$d' $1 > $1.json


