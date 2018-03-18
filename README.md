drilling-data-tools
===================
_Conda Environment: wells_

Acquisition and management tools for oil and gas drilling data

Last updated 3/18/2018.


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
pip install lxml ipython-sql
```

## Steps
1. Download raw data to CSV files following the steps in `source-to-csv.ipynb`
2. Create a local PostgreSQL + PostGIS database using `create-database.ipynb`
3. Import the CSVs into the database using `csv-to-db.csv` and the processing "map" files in the fieldmaps folder
4. Export the well data to a .bin file using `database-to-bin.csv`


# Testing
Export well data using `database-to-bin.ipynb` then fire up an HTTP server (`python3 -m http.server`) and launch [wells.html](wells.html)