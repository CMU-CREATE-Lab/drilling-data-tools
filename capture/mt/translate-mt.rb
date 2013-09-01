#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + '/../libs/utils.rb'

def reload
  load __FILE__
end

def read_all_surface_locations
  wells = []
  src = 'data/all-surface-locations.xls'
  fieldnames = nil
  File.open(src, 'r:iso8859-1:utf-8') do |i|
    i.each do |line|
      line.chomp!
      next if line.empty?
      fields = line.split "\t", -1
      if !fieldnames 
        fieldnames = fields
      else
        if fields.size != fieldnames.size
          raise "#{fieldnames.size} field names (first row) != #{field.size} fields"
        end
        well = Hash[*fieldnames.zip(fields).flatten]
        wells << well
      end
    end
  end
  STDERR.puts "Read #{wells.size} wells from #{src}"
  wells
end

def parse_date(date)
  if !date || date.empty?
    return nil
  end
  date = date.split[0]
  Date.strptime(date, '%m/%d/%Y').to_time.to_i
end

def main
  # The xls files are really tab-delimited
  translated_wells = []
  read_all_surface_locations.each do |well|
    translated = {}
    translated['API'] = well['API #']
    translated['Date'] = parse_date well['Dt_Cmp']
    translated['Lat'] = well['Wh_Lat'].to_f
    translated['Lon'] = well['Wh_Long'].to_f
    if translated['API'] && translated['Date'] && translated['Lat'] && translated['Lon'] &&
        translated['Lat'] != 0
      translated_wells << translated
    end
  end

  translated_wells.sort! {|a,b| a['Date'] <=> b['Date']}
  
  write_compact_json "data/translated-mt.json", translated_wells
end

main
