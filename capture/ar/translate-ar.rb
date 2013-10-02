#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + "/../libs/utils.rb"

def reload
  load __FILE__
end

def parse_date(date)
  begin
    return Date.strptime(date, '%m/%d/%Y').to_time.to_i
  rescue
    return false
  end
end

def main
  out = []
  warnings = Hash.new(0)
  properties = Hash.new(0)
  count = 0
  Dir.glob("data/ar-*.json").each do |file|
    json = read_json file
    json.each do |well|
      count += 1
      translated = {}
      api = well['API Well #']
      if not api
        warnings['Missing API'] += 1
        next
      end
      if api.size != 14
        warnings['API not 14 chars'] += 1
        next
      end
      translated['API'] = [api[0...2], api[2...5], api[5...10], api[10...12]].join('-')
      production = well['Production'] && well['Production'][0]
      if production
        properties['Has Production'] += 1
        # Get date in the following priority order
        ['Completed', 'First Produced', 'Status Date'].each do |datefield|
          if parse_date(production[datefield])
            translated['Date'] ||= parse_date(production[datefield])
            properties["Has production #{datefield} date"] += 1
          end
        end
      end
      
      if parse_date(well['Status Date'])
        properties['Has Status Date'] += 1
        translated['Date'] ||= parse_date(well['Status Date'])
      end
      
      translated['Date'] ||= parse_date(well['Status Date'])
      if not translated['Date']
        warnings['Missing date'] += 1
        next
      end
      
      if well['kml']['FAYSHALE'] == 'Y'
        translated['Fracked'] = true
        properties['Is fracked (FAYSHALE)'] += 1
      end
          
      case well['Well Type']
      when 'GAS'
        translated['Type'] = 'Gas'
        properties['Is Gas well'] += 1
      when 'OIL'
        translated['Type'] = 'Oil'
        properties['Is Oil well'] += 1
      else
        warnings["Don't know 'Well Type' '#{well['Well Type']}'"] += 1
      end
      
      translated['Lat'] = well['Surface Location']['Latitude'].to_f;
      translated['Lon'] = well['Surface Location']['Longitude'].to_f;
      out << translated
    end
  end
  
  STDERR.puts "Total #{count} wells"
  warnings.each do |warning, count|
    STDERR.puts "Warning: '#{warning}' happened #{count} times"
  end
  properties.keys.sort.each do |key|
    STDERR.printf("%s: %.2f%% (%d of %d)\n", key, 100.0 * properties[key] / count, properties[key], count)
  end
  out.sort! {|a,b| a['Date'] <=> b['Date']}
  write_compact_json 'data/translated-ar.json', out
end

