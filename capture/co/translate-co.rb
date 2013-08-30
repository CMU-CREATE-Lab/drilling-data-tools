#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + "/../libs/utils.rb"

def reload
  load __FILE__
end

def translate_file(file)
  ret = []
  permits = read_json file
  permits.each do |permit|
    translated = {}
    translated['API'] = '05-' + permit['api_county'] + '-' + permit['api_seq_nu']
    translated['Date'] = ''
    
    completion_dates = []
    treatment_dates = []
    ((permit['parsed_cogis']['Surface Location Data'] || {})['Wellbore Data for Sidetrack'] || []).each do |sidetrack|
      case sidetrack['Wellbore Permit']['Type']
      when 'DIRECTIONAL', 'HORIZONTAL', 'DRIFTED', 'HIGH ANGLE'
        translated['Nonvertical'] = true
      when 'VERTICAL', ''
      else
        raise "Can't parse Type '#{sidetrack['Wellbore Permit']['Type']}'"
      end
        
      begin
        completion_dates << Date.strptime(sidetrack['Wellbore Completed']['Completion Date'], '%m/%d/%Y').to_time.to_i
      rescue
      end
      ((sidetrack['Wellbore Completed'] || {})['Completed information for formation'] || []).each do |formation| 
        formation['Formation Treatment'].each do |treatment|
          begin
            treatment_dates << Date.strptime(treatment['Treatment Date'], '%m/%d/%Y').to_time.to_i
          rescue
          end
        end
      end
    end
    #puts "completion dates: #{completion_dates.inspect}"
    #puts "treatment dates: #{treatment_dates.inspect}"

    
    if treatment_dates.size > 0
      translated['Treatments'] = treatment_dates.size
    end
    
    translated['Lat'] = permit['lat']
    translated['Lon'] = permit['long']

    (completion_dates + treatment_dates).each do |date|
      clone = translated.clone
      clone['Date'] = date
      ret << clone
    end
  end
  puts "Translated into #{ret.size} records"
  ret
end

def main
#  translate_file(Dir.glob("data/co-001*.json")[0])
  translated = Dir.glob("data/co-[0-9]*.json").flat_map {|file| translate_file file}
  translated.sort! {|a,b| a['Date'] <=> b['Date']}
  write_compact_json "data/translated-co.json", translated
  nil
end

main


