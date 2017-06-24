#!/bin/sh
echo "Compiling scriptscript, fy, gram, gram2..."
iced -o lib -c src
iced -o lib/node_modules/fy -c node_modules/fy/*.coffee
iced -o lib/node_modules/gram -c node_modules/gram/*.coffee
iced -o lib/node_modules/gram2 -c node_modules/gram2/*.coffee
echo "done"