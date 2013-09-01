#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + '/../libs/utils.rb'

def reload
  load __FILE__
end

def main
  wells = 
  translated_wells = []

  wells = read_json 'data/ut-completions.json'
  wells.each do |well|
    translated = {}
    api = well['API Number']
    translated['API'] = "#{api[0 ... 2]}-#{api[2 ... 5]}-#{api[5 .. -1]}"
    # Convert epoch time in milliseconds to epoch time in seconds
    translated['Date'] = Date.strptime(well['CompletionDate'], '%m/%d/%Y').to_time.to_i
    translated['Lat'] = well['Latitude'].to_f
    translated['Lon'] = well['Longitude'].to_f
    if translated['API'] && translated['Date'] &&
        translated['Lat'] != 0 && translated['Lon'] != 0
      translated_wells << translated
    end
  end
  translated_wells.sort! {|a,b| a['Date'] <=> b['Date']}
  write_compact_json "data/translated-ut.json", translated_wells
end

main

