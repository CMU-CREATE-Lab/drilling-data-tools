#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + "/../libs/utils.rb"

# $fetch_url_use_proxy = true

def reload
  load __FILE__
end

def scrape_well(api)
  url = "http://www.aogc2.state.ar.us/AOGConline/ED.aspx?KeyName=API_WELLNO&KeyValue=#{api}&KeyType=STRING&DetailXML=WellDetails.xml"
  begin
    $fetch_retry_on_error = 60
    html = fetch_url url
    
    doc = nokogiri_parse_html html
    
    # Parse header
    well = interleaved_table_to_hash find_row_matching(doc, /Permit.*Well Name.*Well Type/m)
    
    # Parse "General" tab
    general = find_table_matching(doc, /API Well #.*Current Operator/m)
    if not general
      STDERR.write "(Well #{api} has no general table)"
      return nil
    end
    well.merge! interleaved_table_to_hash general
    
    # Parse Surface Location
    well['Surface Location'] = interleaved_table_to_hash find_table_matching(doc, /Legal S-T-R.*Footage NS/m)
    
    # Parse Production
    well['Production'] = table_to_hashes find_table_matching(doc, /Lease.*Status.*Formation/m)
    
    # Parse Injection
    well['Injection'] = table_to_hashes find_table_matching(doc, /Gas Volume.*Liquid Volume/m)
    
    well
  rescue => e
    STDERR.puts "Exception #{e.to_s} while scraping well #{api} (#{url})"
    STDERR.puts e.backtrace
  end
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

def main
  wells = read_wells 'data/Natural_Gas_and_Oil_Wells.kml'
  well_groups = {}
  wells.each do |well|
    (well_groups[well['API'][0 ... 8]] ||= []) << well
  end
  STDERR.puts "#{well_groups.size} groups of wells (max group size = #{well_groups.values.map{|g|g.size}.max})"

  wells_done = 0
  
  well_groups.map do |name, group|
    dest = "data/ar-#{name}.json"
    STDERR.printf "%.1f%% ", wells_done * 100.0 / wells.size
    if File.exists? dest
      STDERR.puts "#{dest} with #{group.size} wells already exists, skipping"
    else
      STDERR.write "#{dest}: fetching #{group.size} wells"
      fullwells = []
      group.each do |well|
        fullwell = scrape_well well['API']
        if fullwell
          STDERR.write '.'
          fullwell['kml'] = well
          fullwells << fullwell
        end
      end
      STDERR.puts 'done.'
      write_json dest, fullwells
    end
    wells_done += group.size
  end
  nil
end

main
