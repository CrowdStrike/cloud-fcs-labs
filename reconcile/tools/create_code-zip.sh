#!/bin/bash

# run from the tools folder before commiting changes made to files in the ./code folder to update code.zip in the templates folder.

cd ../deployFalcon/code/
zip -r code.zip * -x "*.DS_Store"
mv ./code.zip ../
