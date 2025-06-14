#!/usr/bin/env bash
cd /home/birder/BirdNET-Pi/birdnet-data
sqlite3 -header -csv .././scripts/birds.db "SELECT * FROM detections;" > alldetect.csv
git add .
git commit -m "Refresh detection data - $(date +%Y-%m-%d)"
git push