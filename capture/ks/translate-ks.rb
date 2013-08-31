#!/usr/bin/env ruby2.0

require 'iconv'

load File.dirname(__FILE__) + "/../libs/utils.rb"

def reload
  load __FILE__
end

def read_wells
  wellfile = 'data/ks_wells.txt'

  # Convert from latin1 to utf-8
  welltxt = File.open(wellfile, "r") {|i| i.read}

  # convert from latin1 to utf-8
  welltxt = Iconv.conv('utf-8', 'latin1', welltxt)

  wells = csv_to_hashes welltxt

  STDERR.puts "Read #{wells.size} wells from #{wellfile}"
  wells
end

def main1
  wells = read_wells
  $wells = wells
  nil
end

def main2
  wells = $wells
  
  translated_wells = []
  
  wells.each do |well|
    translated = {}
    # form 15-CCC-IIIII-SSSS
    translated['API'] = well['API_NUMBER']
    date = well['COMPLETION']
    if date == ''
      date = well['SPUD']
    end
    if date == ''
      date = well['PERMIT']
    end
    
    if date != ''
      translated['Date'] = Date.strptime(date, '%d-%b-%Y').to_time.to_i
    end

    translated['Lat'] = well['LATITUDE'].to_f
    translated['Lon'] = well['LONGITUDE'].to_f

    if translated['Date']
      translated_wells << translated
    end
  end

  translated_wells.sort! {|a,b| a['Date'] <=> b['Date']}
  
  write_compact_json "data/translated-ks.json", translated_wells
end
