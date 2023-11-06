#!/bin/sh
if [ -z "$CS_SCAN_IMAGE" ]; then
    echo "WARNING: CS_SCAN_IMAGE is not set, skipping image scan"
    exit 0
fi
echo "Installing the required dependencies"
pip3 install docker requests
pip3 install crowdstrike-falconpy
echo "Running CS Image Scan script"
#python3 ./cs_image_scan/cs_scanimage.py -r $REPOSITORY_URI -t latest -s 25000 -c $CS_CLOUD
python3 ./cs_image_scan/cs_scanimage.py -r $REPOSITORY_URI -t $IMAGE_TAG -s 25000 -c $CS_CLOUD
