#!/usr/bin/env ruby2.0

require "csv"

load File.dirname(__FILE__) + "/../libs/web.rb"
load File.dirname(__FILE__) + "/../libs/daterange.rb"

def reload
  load __FILE__
end

#
# type can be one of "Gas Well", "Oil Well", or "Oil or Gas Well" (which is, counterintuitively, a separate category)
# returns nil if too many

def fetch_permits(daterange, type)
  if daterange.duration > 600
    # Range larger than 600 days; split and try again
    return nil
  end

  browser.goto "http://webapps2.rrc.state.tx.us/EWA/drillingPermitsQueryAction.do"
  browser.select_list(:name, /wellTypeCode/).select(type)
  browser.text_field(:name, /submittedDtFrom/).set(daterange.from.strftime("%m/%d/%Y"))
  # daterange is exclusive of last date, but form assumes inclusive, so subtract a day
  browser.text_field(:name, /submittedDtTo/).set((daterange.to-1).strftime("%m/%d/%Y"))
  browser.button(:value, "Submit").click

  if browser.text.include? 'exceeds the maximum'
    # Too many to return
    return nil
  end

  if browser.text.include? 'No results found'
    return []
  end

  csv = download {
    browser.button(:value, "Download").click
  }

  # Parse CSV into one hash per record
  fieldnames = nil
  records = []
  CSV.parse(csv).each do |fields|
    # Ignore idiosyncratic header lines, which have 0 or 1 fields
    if fields.size > 1
      if fieldnames
        record = Hash[*fieldnames.zip(fields).flatten]
        record['type'] = type
        records << record
      else
        # First set of fields represent field names
        fieldnames = fields
      end
    end
  end
  records
end


def collect_permits(daterange, type, indent = 0)
  permits = fetch_permits(daterange, type)
  if !permits
    STDERR.puts "#{"  " * indent}#{daterange} #{type}: too large; dividing"
    permits = daterange.split.flat_map {|daterange| collect_permits(daterange, type, indent + 1)}
  end
  STDERR.puts "#{"  " * indent}#{daterange} #{type}: #{permits.size} permits"
  permits
end

def collect_all_permits(daterange)
  permits = ["Gas Well", "Oil Well", "Oil or Gas Well"].each.flat_map do |type|
    collect_permits(daterange, type)
  end
  STDERR.puts "#{daterange} all: #{permits.size} permits"
  permits
end

def main
  daterange = DateRange.new(Date.new(1950, 1, 1), Date.today)
  permits = collect_all_permits(daterange)
  puts JSON.pretty_generate(permits)
end

main
