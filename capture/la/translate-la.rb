#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + "/../libs/utils.rb"

def reload
  load __FILE__
end

def parse_ll(ll)
  if !ll || ll == "Not on file" || ll == "0-0-0"
    return nil
  end
  fields = ll.split("-").map &:to_f
  if fields.size != 3
    raise "Can't parse latlon #{ll}"
  end
  return fields[0] + fields[1] / 60.0 + fields[2] / 3600.0;
end

def parse_date(date)
  if !date || date == ''
    return nil
  end
  Date.strptime(date, '%m/%d/%Y').to_time.to_i
end

def main
  translated_wells = []
  Dir.glob("data/la-???000.json").each do |file|
    wells = read_json file
    # NAD-27?
    wells.each do |well|
      translated = {}
      $well = well

      api = (well['WELLS'][0] || {})['API NUM']
      next if !api || api == ''

      translated['API'] = "#{api[0 ... 2]}-#{api[2 ... 5]}-#{api[6 .. -1]}"
      translated['Date'] = nil
      translated['Lat'] = parse_ll(well['WELL SURFACE COORDINATES'][0]['Surface Latitude'])
      translated['Lon'] = parse_ll(well['WELL SURFACE COORDINATES'][0]['Surface Longitude'])
      if !translated['Lat'] || !translated['Lon']
        next
      end
      translated['Lon'] = -translated['Lon']

      # Find completions dates.  Failing that, use spud date or permit date
      dates = []
      (well['CASING'] || []).each do |casing|
        dates << parse_date(casing['COMPLETION_DATE'])
      end
      dates.compact!
      if dates.empty?
        dates << (parse_date well['WELLS'][1]['SPUD DATE'] || parse_date['WELLS'][1]['PRMT DATE'])
      end
      dates.compact!
      dates = dates.sort.uniq
        
      # Insert record for each completion
      dates.each do |date|
        clone = translated.clone
        clone['Date'] = date
        translated_wells << clone
      end
    end
  end
  
  translated_wells.sort! {|a,b| a['Date'] <=> b['Date']}
  write_compact_json 'data/translated-la.json', translated_wells
end

main
