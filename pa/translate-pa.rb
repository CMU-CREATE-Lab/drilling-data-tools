#!/usr/bin/env ruby2.0

require "csv"
require "iconv"
load File.dirname(__FILE__) + "/../libs/utils.rb"

def csv_to_hashes(csv)
  fieldnames = nil
  rowno = 0
  ret = []
  CSV.parse(csv) do |fields|
    if fields.size == 0
      # skip
    elsif fieldnames
      rowno += 1
      fieldnames.size == fields.size or raise "Header has #{fieldnames.size} elements, but row #{rowno} has #{fields.size} elements"
      hash = {}
      ret << Hash[*fieldnames.zip(fields).flatten]      
    else
      fieldnames = fields
    end
  end
  ret
end

csv = open("data/Permits_Issued_Detail.csv") {|i| i.read}
# from latin1 to utf-8
csv = Iconv.conv('utf-8', 'latin1', csv)

permits = csv_to_hashes csv

puts "Read #{permits.size} permits"

json = permits.map do |permit|
  translated = {}
  translated['API'] = '37-' + permit['WELL_API']
  translated['Date'] = Date.strptime(permit['PERMIT_ISSUED_DATE'], '%m/%d/%Y').to_time.to_i

  case permit['WELL_TYPE']
  when 'OIL'
    translated['Type'] = 'Oil'
  when 'GAS', 'COALBED METHANE'
    translated['Type'] = 'Gas'
  when 'COMB. OIL&GAS'
    translated['Type'] = 'Oil+Gas'
  when 'STORAGE WELL'
    translated['Type'] = 'Storage'
  when 'WASTE DISPOSAL'
    translated['Type'] = 'Disposal'
  when 'INJECTION'
    translated['Type'] = 'Injection'
  when 'Multiple Well bore type'
    translated['Type'] = 'Multiple bore'
  when 'UNDETERMINED'
  when 'TEMP UNSPECIFY'
  when 'DRY HOLE'
  when 'OBSERVATION'
  when 'TEST'
  else
    raise "Can't parse WELL_TYPE from #{permit}"
  end
              
  case permit['CONFIGURATION']
  when 'Vertical Well', 'Deviated Well'
    translated['Nonvertical'] = true
  when 'Horizontal Well', 'Undetermined'
  else
    raise "Can't parse CONFIGURATION '#{permit['CONFIGURATION']}' (#{permit})"
  end

  case permit['UNCONVENTIONAL']
  when 'Yes'
    translated['Unconventional'] = true
  when 'No'
  else
    raise "Can't parse UNCONVENTIONAL from #{permit}"
  end

  translated['Lat'] = permit['LATITUDE_DECIMAL'].to_f
  translated['Lon'] = permit['LONGITUDE_DECIMAL'].to_f

  translated
end

json.sort! {|a,b| a['Date'] <=> b['Date']}

dest = "data/translated-pa.json"
write_compact_json(dest, json)
puts "Wrote #{json.size} records to #{dest}"
