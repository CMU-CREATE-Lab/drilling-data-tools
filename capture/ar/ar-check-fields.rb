#!/usr/bin/env ruby2.0

require "json"
require "set"

fields = open("data/ar-fields.json") {|f| JSON.parse(f.read)}

wellcount = 0
apis = Set.new

fields.each do |field|
  field["wells"].each do |well|
    wellcount += 1
    apis << well["API WELL NO."].to_i / 10000
  end
end

ranges = []
current_range = nil

apis.sort.each do |api|
  api = api.to_i
  if current_range && current_range.max + 1 == api
    # Extend current range
    current_range = (current_range.min .. api)
  else
    # Start new range
    if current_range
      ranges << current_range
    end
    current_range = (api .. api)
  end
end

puts "Found #{wellcount} wells (#{apis.size} unique) in #{ranges.size} contiguous ranges:"

exit 0

ranges.size.times do |i|
  STDOUT.write "#{ranges[i]}"
  if i + 1 < ranges.size
    STDOUT.write " (gap = #{ranges[i + 1].min - ranges[i].max - 1})"
  end
  puts
end

  
  
