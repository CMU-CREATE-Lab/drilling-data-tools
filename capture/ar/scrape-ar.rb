#!/usr/bin/env ruby2.0

require File.dirname(__FILE__) + "/../libs/utils"

#(1 ... 149).step(2).each do |county|
#  (10001 ... 
#end
def reload
  load __FILE__
end

# Yuck.  max 100 accesses in 30 mins?  

def fetch_field(fieldno)
  url = "http://www.aogc2.state.ar.us/AOGConline/ED.aspx?KeyName=St_FldNo&KeyValue=#{fieldno}&KeyType=INTEGER&DetailXML=FieldDetails.xml"
  $fetch_retry_on_error = 60
  html = fetch_url url
  $doc = nokogiri_doc html
  open("html","w"){|f| f.write html}
  
  if $doc.css("tr")[1].css("td")[0].text != "Name"
    STDERR.puts "Field #{fieldno} doesn't exist"
    # No such field
    return nil
  end

  first_row = $doc.css("tr")[1].css("td").map &:text # 4 elts: Name (name) Number (number)
  field = Hash[*first_row]

  # Surgery: remove first row of each table, since each #EDIn table seems to have an empty row at top
  $doc.css("table").each {|table| table.css("tr")[0].remove}
  field["pools"] = table_to_hashes $doc.css("#EDI0 table")
  field["wells"] = table_to_hashes $doc.css("#EDI1 table")
  field["annual_production"] = table_to_hashes $doc.css("#EDI2 table")
  field["monthly_production"] = table_to_hashes $doc.css("#EDI3 table")
  STDERR.puts "Field #{fieldno} has #{field["wells"].size} wells"
  field
end

def write_fields
  dest = "data/ar-fields.json"
  if File.exists? dest
    STDERR.puts "#{dest} already exists, skipping"
  else
    STDERR.puts "Creating #{dest}"
    fields = (1 ... 1000).map do |field| 
      sleep 2
      fetch_field field
    end
    fields.compact!
    write_json dest, fields
  end
end

def main
  write_fields
end

main


