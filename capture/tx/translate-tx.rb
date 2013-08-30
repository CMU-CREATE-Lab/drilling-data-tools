#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + "/../libs/utils.rb"

def reload
  load __FILE__
end

def read
  $permits = read_json "data/tx-permits.json"
  
  $locations = read_json "data/tx-locations.json"
  
  $locs = {}
  
  $locations.each do |loc|
    $locs[loc['SDE.WELLSURF_VW.API']] = {
      'Lat' => loc['SDE.WELLSURF_VW.GIS_LAT83'].to_f,
      'Lon' => loc['SDE.WELLSURF_VW.GIS_LONG83'].to_f
    }
  end

  nil
end

def translate
  located_permits = []
  $permits.each do |permit|
    api = permit['API NO.']
    loc = $locs[api]
    if loc
      translated = {}
      api.size == 8 or raise "api '#{api}' not 8 chars"
      translated['API'] = '42-' + api[0...3] + '-' + api[3..-1]
      if permit['Status Date'] =~ /Approved (\S+)/
        translated['Date'] = Date.strptime($1, '%m/%d/%Y').to_time.to_i
      elsif permit['Status Date'] =~ /Approved $/
        # No approval date.  Skip this permit
        next
      else
        raise "Can't parse Status Date from #{permit}"
      end

      case permit['type']
      when 'Gas Well'
        translated['Type'] = 'Gas'
      when 'Oil Well'
        translated['Type'] = 'Oil'
      when 'Oil or Gas Well'
        translated['Type'] = 'Oil+Gas'
      else
        raise "Can't parse 'type' from #{permit['type']} (#{permit})"
      end

      (permit['Wellbore Profile'] || '').split(/\W+/).each do |token|
        case token
        when 'Vertical', 'Sidetrack'
        when 'Directional', 'Horizontal'
          translated['Nonvertical'] = true
        else
          raise "Can't parse 'Wellbore Profile' '#{token}' (#{permit})"
        end
      end

      translated.merge! loc
      
      located_permits << translated
    end
  end

  located_permits.sort! {|a,b| a['Date'] <=> b['Date']}

  write_compact_json 'data/translated-tx.json', located_permits
end

def main
  read
  translate
end

main
