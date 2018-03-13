drilling-data-tools
===================
_Conda Environment: wells_

Acquisition and management tools for oil and gas drilling data

Last updated 8/2/16.

The starting point for building the national dataset is FracTracker's 2015 dataset,
available from: https://github.com/FracTrackerAlliance/National2015

For all of the states WITHOUT dates, scripts have been written to download the data.

Most of these scripts are Python scripts within 'capture/multi-state-capture-scripts.ipynb'

These scripts can download shape files, csv files, and scrape ArcGIS servers.

Texas's permit dates are scraped in Ruby, using "watir-webdriver".

## Requirements
* Python 3
* Jupyter
* Psycopg2
* ArcGIS Python API
* Selenium Webdrive
* requests
* lxml


## Environment Setup
```bash
conda create -n wells python jupyter psycopg2 requests
source activate wells
conda install -c esri arcgis
pip install lxml
```