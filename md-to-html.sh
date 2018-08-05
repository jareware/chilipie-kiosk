#!/bin/bash

if [ ! -d "node_modules" ]; then
    npm install markdown-styles@3.1.10 html-inline@1.2.0
fi

rm -rf md-input md-output
mkdir md-input md-output
cp first-boot.md md-input
./node_modules/.bin/generate-md --layout github --input md-input/ --output md-output/
./node_modules/.bin/html-inline -i md-output/first-boot.html > home/first-boot.html
rm -rf md-input md-output
