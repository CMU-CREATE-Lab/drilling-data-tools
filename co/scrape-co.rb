#!/usr/bin/env ruby2.0

# Scrape Colorado well information
# Inputs: WELLS.DBF, http://cogcc.state.co.us
# Outputs: co-unparsed-NNNNNNNN.json
# See https://docs.google.com/document/d/1p1Hp4GECdoARMexrUfQAYlR4mF3E_ljbQRMBSMuvGXU/edit?usp=sharing for more info

require "dbf"
require "iconv"

load File.dirname(__FILE__) + "/../libs/utils.rb"

def reload
  load __FILE__
end

def get_wells_from_dbf
  STDERR.write "Getting wells from DBF"
  wells = []
  ticks = Ticks.every(5000)
  wells = DBF::Table.new("data/WELL_SHP/WELLS.DBF").map do |well|
    ticks.increment
    well.attributes
  end
  STDERR.write " #{wells.size} wells\n"
  wells.sort {|a,b| a["link_fld"] <=> b["link_fld"]}
end

# API starts with county and has no punctuation, e.g. 12508169
def fetch_cogis_well_info(api)
  html = fetch_url "http://cogcc.state.co.us/cogis/FacilityDetail.asp?facid=#{api}&type=WELL"
  # Convert from latin1 to utf-8
  Iconv.conv('utf-8', 'latin1', html)
end

def fetch_all_wells
  wells = get_wells_from_dbf
  
  # Collect wells into batches of 1K
  batch_size = 1000
  batches = {}
  wells.each do |well|
    # link_fld consists of 3-digit county followed by 5-digit sequence
    batchno = well["link_fld"].to_i / batch_size
    (batches[batchno] ||= []) << well
  end
  
  puts "#{batches.size} batches totalling #{wells.size} wells"

  # Fetch details from each batch
  batches.keys.sort.each_with_index do |batchno, i| 
    filename = sprintf "data/co-unparsed-%08d.json", batchno * batch_size
    if File.exists? filename
      STDERR.puts "#{filename} already exists, skipping"
    else 
      wells = batches[batchno]
      STDERR.write "Creating #{filename} (#{wells.size} wells)"
      ticks = Ticks.every 10
      wells.each do |well|
        well["unparsed_cogis"] = fetch_cogis_well_info(well["link_fld"])
        ticks.increment
      end
      write_json(filename, wells)
      STDERR.write "done\n"
      # Clear out data we don't need any more
      batches[batchno] = []
    end
    printf "Progress %.1f%%\n", 100.0 * (i + 1) / batches.size
  end
end

def main
  fetch_all_wells
end

main
