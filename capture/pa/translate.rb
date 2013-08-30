#!/usr/bin/ruby

require 'CSV'

CSV.foreach("Permits_Issued_Detail.csv") do |row|
  if row.size != 23
    puts yo
  end
end
