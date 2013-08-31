#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + "/../capture/libs/utils.rb"

def reload
  load __FILE__
end

def main
  wells = Dir.glob("../capture/??/data/translated-??.json").flat_map do |file|
    read_json file
  end
  wells.sort! {|a,b| a['Date'] <=> b['Date']}
  #wells = wells.last(100000)
  write_compact_json "wells.js.tmp", wells
  open("wells.js", "w") do |out|
    out.write "wells="
    out.write open("wells.js.tmp"){|i| i.read}
    out.puts ";"
  end
  File.unlink "wells.js.tmp"
end

main
