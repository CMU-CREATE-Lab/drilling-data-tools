#!/usr/bin/env ruby2.0

require 'json'

load File.dirname(__FILE__) + "/../libs/kml.rb"

wells = open("data/tx-locations.json") {|f| JSON.parse(f.read)}

placemarks = wells.map do |well|
  { 
    "lat" => well["SDE.WELLSURF_VW.GIS_LAT83"],
    "lon" => well["SDE.WELLSURF_VW.GIS_LONG83"],
    "description" =>  well["SDE.WELLSURF_VW.API"]
  }
end

write_kml "data/tx.kml", placemarks
