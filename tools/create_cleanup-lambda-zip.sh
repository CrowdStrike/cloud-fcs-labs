#!/bin/bash

# run from the tools folder before commiting changes made to files in the ./cleanup_lambda folder to update cleanup_lambda.zip in the templates folder.

cd ../cleanup_lambda/
zip -r cleanup_lambda.zip * -x "*.DS_Store"
mv ./cleanup_lambda.zip ../
