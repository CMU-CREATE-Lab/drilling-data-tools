#!/usr/bin/env ruby2.0

require "csv"

load File.dirname(__FILE__) + "/../libs/daterange.rb"
load File.dirname(__FILE__) + "/../libs/utils.rb"
load File.dirname(__FILE__) + "/../libs/web.rb"

def reload
  load __FILE__
end

# #
# # type can be one of "Gas Well", "Oil Well", or "Oil or Gas Well" (which is, counterintuitively, a separate category)
# # returns nil if too many
# 
def fetch_permit(id)
  browser.goto "http://www.occpermit.com/WellBrowse/Webforms/WellInformation.aspx?ID=#{id}"
  if browser.text_field(:id, /APINumber/).value.empty?
    return nil
  end
  record = {}
  browser.text_fields.each do |textfield|
    key = textfield.name.split("$")[-1].sub("txt", "")
    record[key] = textfield.value.strip
  end
  browser.button(:value, "Completions").click
  completions = browser.frame(:id, /contentRight/).table(:id, /Completion/).when_present.to_a
  # Remove any blank columns from left of table
  while (completions[0][0].strip.empty?) do
    completions.each &:shift
  end
  fieldnames = completions.shift
  record['completions'] = completions.map do |completion|
    Hash[*fieldnames.zip(completion).flatten]
  end
  record
end

def main
  batch_size = 1000
  last_well = 600000
  (0 ... last_well).step batch_size do |start|
    filename = sprintf("data/ok-%06d.json", start)
    if File.exists? filename
      STDERR.puts "#{filename} already exists, skipping"
    else
      STDERR.write "Creating #{filename} (#{start} - #{start + batch_size - 1})"
      permits = (start...(start + batch_size)).map{ |i|
        (i % 5 == 0) and STDERR.write "."
        fetch_permit i 
      }.compact
      write_json filename, permits
      STDERR.puts "\nWrote #{permits.size} permits to #{filename}"
    end
    STDERR.printf "Progress: %.1f%%\n", 100.0 * (start + batch_size) / last_well
  end
end

main
