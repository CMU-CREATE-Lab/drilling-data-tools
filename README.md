drilling-data-tools
===================
_Conda Environment: wells_

Acquisition and management tools for oil and gas drilling data.

Author: Mark Egge [mark@eateggs.com]

Last Updated: 3/18/2018

# About the Data
The National Oil and Gas dataset presents a compilation of all drilling permit records from all 34 oil and gas producing states. The dataset compiles the publicly available oil and gas drilling records, showing when and where oil and gas wells have been drilled.

Each state maintains a permitting program for drilling wells, and keeps a record of the permitted wells. This data is publicly available, and typically includes the well type, well status (active, plugged and abandoned, etc.) and spud date (the date when drilling is completed). 

Of the many types of drilled wells associated with oil and gas production (exploration, observation, injection control, storage, etc.), this dataset shows only wells drilled for the purpose of producing oil and/or gas. The dataset shows the surface location of the bore holes. With the advent of horizontal drilling, multiple wells may be drilled from the same surface pad. These wells would have the same surface hole location, but different bottom hole locations. 

In some cases, the date information associated with older wells is missing or incomplete. Wells drilled in Texas prior to 1970, for example, do not have date information available. Where missing or incomplete, the wells without date data have been assigned a random date after the onset of signifcant commercial drilling within the respective state.

Data for Arkansas, Kentucky, Mississippi, Nebraska, and Oklahoma wells comes from the National Oil and Gas Gateway. Data for Maryland's gas wells is provided by FracTracker. Data for the Osage Reservation in Oklahoma is not included at this time. This data includes near-shore developments for wells included in the state dataset and within 25 km of the shore. The data does not include other off-shore drilling activity. The data includes wells drilled through March 20, 2018.

The well data can be explored at https://cmu-create-lab.github.io/drilling-data-tools/national-database/wells.html

# Instructions for Updating the Data

## Environment Requirements
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

# Oil and Gas Learning Resources:
* Class II Injection Wells: https://www.epa.gov/uic/class-ii-oil-and-gas-related-injection-wells

_Other Notes_
Spud dates are only available for Texas wells drilled since 1970. The records for the 1m+ wells drilled in Texas prior to 1970 are available on microfische slides, and Texas Railroad Commission (which permits drilling in Texas) has not undertaken the effort to digitize this data.

There are many types of wells associated with oil and gas extraction, in addition to the bore holes through which the oil or gas is extracted. These include injection wells (used to "push" oil or gas toward an extraction well), disposal wells (used to dispose of drilling byproducts, such as brackish water produced from a gas well), storage wells (used to temporarily store gas underground), test and observation wells, and dry holes. Of these many types of wells, only oil and gas producing bore holes have been included.
