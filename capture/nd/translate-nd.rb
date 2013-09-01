#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + '/../libs/utils.rb'

def reload
  load __FILE__
end

def main
  wells = 
  translated_wells = []

  wells = read_json 'data/nd.json'
  wells.each do |well|
    translated = {}
    translated['API'] = well['sde10_ogd.SDE.wells.api_no']
    # Convert epoch time in milliseconds to epoch time in seconds
    translated['Date'] = well['sde10_ogd.SDE.wells.spud_date'].to_i / 1000
    translated['Lat'] = well['sde10_ogd.SDE.wells.latitude'].to_f
    translated['Lon'] = well['sde10_ogd.SDE.wells.longitude'].to_f
    if translated['API'] && translated['Date'] != 0 &&
        translated['Lat'] != 0 && translated['Lon'] != 0
      translated_wells << translated
    end
  end
  translated_wells.sort! {|a,b| a['Date'] <=> b['Date']}
  write_compact_json "data/translated-nd.json", translated_wells
end

main
