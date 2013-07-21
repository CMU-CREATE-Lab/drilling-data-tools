#!/usr/bin/env ruby2.0

require "json"
require "open-uri"

$LOAD_PATH.unshift(File.dirname(__FILE__) + "/../libs")
require "bounds"

def fetch(bounds)
  url = "http://services.arcgis.com/jDGuO8tYggdCCnUJ/arcgis/rest/services/FracFocus_Wells/FeatureServer/0/query?f=json&returnGeometry=true&spatialRel=esriSpatialRelIntersects&maxAllowableOffset=152&geometry=#{JSON.dump(bounds.to_hash.merge({"spatialReference"=>{"wkid"=>102100}}))}&geometryType=esriGeometryEnvelope&inSR=102100&outFields=*&outSR=102100"
  json = open(URI::encode(url)) {|f| JSON.parse(f.read)}
  !json["exceededTransferLimit"] && (json["features"] || [])
end

def collect(bounds, nest = 0)
  wells = fetch(bounds)
  if !wells
    STDERR.puts "#{"  " * nest}#{bounds}: too many; dividing"
    wells = bounds.split.flat_map {|bounds| collect(bounds, nest + 1)}
  end
  STDERR.puts "#{"  " * nest}#{bounds}: #{wells.size} wells"
  wells
end

bounds = Bounds.new(-25000000.0, 0.0, 0.0, 25000000.0)

# Smaller bounds for testing:
# bounds = Bounds.new(-9375000.0, 4687500.0, -7812500.0, 6250000.0)

wells = collect(bounds)
puts JSON.pretty_generate(wells)
