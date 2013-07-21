#!/usr/bin/env ruby2.0

require "json"
require "nokogiri"

load File.dirname(__FILE__) + "/../libs/web.rb"
load File.dirname(__FILE__) + "/../libs/utils.rb"

# Wells seem to be defined roughly from 1 to 250K

def reload
  load __FILE__
end

def fetch_well(sn)
  html = fetch_url "http://sonlite.dnr.state.la.us/sundown/cart_prod/cart_con_wellinfo2?p_WSN=#{sn}"
  doc = Nokogiri::HTML(html) {|config| config.strict.nonet}
  # Find all the top-level <b> and <table> elements
  elts = doc.css("body b,body table").sort
  record = {}
  section = nil
  elts.each do |elt|
    if elt.name == "table"
      section or raise "Parser assumes a section name in <b> prior to table"
      record[section] = (record[section] || []) + table_to_hashes(elt)
    else
      section = elt.text
    end
  end
  if record.values.all? &:empty?
    # If all fields are empty, there's no well
    nil
  else
    record
  end
end

def main
  batch_size = 1000
  last_well = 250000
  (0 ... last_well).step batch_size do |start|
    filename = sprintf("data/la-%06d.json", start)
    if File.exists? filename
      STDERR.puts "#{filename} already exists, skipping"
    else
      STDERR.write "Creating #{filename} (#{start} - #{start + batch_size - 1})"
      ticks = Ticks.every 10
      wells = (start...(start + batch_size)).map { |i|
        ticks.increment
        fetch_well i 
      }.compact
      write_json filename, wells
      STDERR.puts "\nWrote #{wells.size} permits to #{filename}"
      # Huge memory leak, so restart to continue scraping
      STDERR.puts "Restarting to clear memory\n"
      exec File.dirname(__FILE__) + "/scrape-la.rb"
    end
    STDERR.printf "Progress: %.1f%%\n", 100.0 * (start + batch_size) / last_well
  end
end

main
