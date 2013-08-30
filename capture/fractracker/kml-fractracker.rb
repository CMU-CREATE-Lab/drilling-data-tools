#!/usr/bin/env ruby2.0

require 'json'
require File.dirname(__FILE__) + "/../libs/kml"

wells = open("data/wells.json") {|f| JSON.parse(f.read)}

placemarks = wells.map do |well|
  { 
    "lat" => well["attributes"]["latitude"],
    "lon" => well["attributes"]["longitude"],
    "description" =>  "#{well["attributes"]["api"]}: #{Time.at(well["attributes"]["fracture_d"]/1000).strftime("%Y-%m-%d")}"
  }
end

write_kml "data/fractracker.kml", placemarks

