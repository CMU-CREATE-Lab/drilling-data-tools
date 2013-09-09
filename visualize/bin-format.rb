#!/usr/bin/env ruby2.0
load File.dirname(__FILE__) + "/../capture/libs/utils.rb"

require 'optparse'
require 'ostruct'
require 'json'

MIN_UNIX_TIME = -2147483647 
MAX_UNIX_TIME = 2147483647 

class CustomFormatOptparse
  def self.parse(args)
    # defaults
    options = OpenStruct.new
    options.file = "wells.js"
    options.keys = ["Date", "Lat", "Lon"]

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: custom-format.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

      opts.on("-f", "--file FILE", "Begin execution at given time") do |file|
        options.file = file
      end
    end

    opt_parser.parse!(args)
    options
  end
end

def main
  options = CustomFormatOptparse.parse(ARGV)
  unless File.exists? options.file
    puts "Could not find or open #{options.file}"
    return
  end
  unix_times = File.open('wells_unix_times.bin', 'wb')
  latlon = File.open('wells_latlon.bin', 'wb')
  data = read_json(options.file)
  data.each do |d|
    if d["Date"].to_i > MIN_UNIX_TIME and d["Date"].to_i < MAX_UNIX_TIME
      unix_times.write([d["Date"].to_i].pack("l<"))
      latlon.write([d["Lat"].to_f].pack("f"))
      latlon.write([d["Lon"].to_f].pack("f"))
    end
  end
  unix_times.close
  latlon.close
end

main
