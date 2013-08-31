#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + "/../libs/utils.rb"

# $fetch_url_use_proxy = true

def reload
  load __FILE__
end

def scrape_well(api)
  $fetch_retry_on_error = 60
  html = fetch_url "http://www.aogc2.state.ar.us/AOGConline/ED.aspx?KeyName=API_WELLNO&KeyValue=#{api}&KeyType=STRING&DetailXML=WellDetails.xml"
    
  doc = nokogiri_parse_html html

  # Parse header
  well = interleaved_table_to_hash find_row_matching(doc, /Permit.*Well Name.*Well Type/m)
  
  # Parse "General" tab
  well.merge! interleaved_table_to_hash find_table_matching(doc, /API Well #.*Current Operator/m)

  # Parse Surface Location
  well['Surface Location'] = interleaved_table_to_hash find_table_matching(doc, /Legal S-T-R.*Footage NS/m)

  # Parse Production
  well['Production'] = table_to_hashes find_table_matching(doc, /Lease.*Status.*Formation/m)
  
  # Parse Injection
  well['Injection'] = table_to_hashes find_table_matching(doc, /Gas Volume.*Liquid Volume/m)
  
  well
end

def read_wells(filename)
  doc = nokogiri_parse_xml_file filename
  wells = doc.css("Placemark").map do |placemark|
    well = {}
    placemark.css("SimpleData").each do |keyval|
      key = keyval.attr("name")
      val = keyval.text
      well[key] = val
    end
    coords = placemark.at_css("coordinates").text.split ","
    well['LATITUDE'] = coords[0]
    well['LONGITUDE'] = coords[1]
    well['API'] && well
  end
  wells.compact!
  STDERR.puts "Read #{wells.size} wells from #{filename}"
  wells
end  

def main1
  wells = read_wells 'data/Natural_Gas_and_Oil_Wells.kml'
  $wells = wells
  nil
end

def main2
  wells = $wells
  well_groups = {}
  wells.each do |well|
    (well_groups[well['API'][0 ... 8]] ||= []) << well
  end
  STDERR.puts "#{well_groups.size} groups of wells (max group size = #{well_groups.values.map{|g|g.size}.max})"
  
  well_groups.map do |name, wells|
    dest = "data/ar-#{name}.json"
    if File.exists? dest
      STDERR.puts "#{dest} with #{wells.size} wells already exists, skipping"
    else
      STDERR.write "#{dest}: fetching #{wells.size} wells"
      fullwells = wells.map do |well|
        fullwell = scrape_well well['API']
        STDERR.write '.'
        fullwell['kml'] = well
        fullwell
      end
      STDERR.puts 'done.'
      write_json dest, fullwells
    end
  end
  nil
end

# $wells.map{|well| well['API'][0 ... 8]}.uniq.size


#if doc.elements["ARCXML/RESPONSE/FEATURES/FEATURECOUNT"].attributes['hasmore'] == "true"
#  # Too many elements
#  return false
#end
