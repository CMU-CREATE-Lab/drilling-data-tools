#!/usr/bin/env ruby2.0

# Parse Colorado well information
# Inputs: co-unparsed-NNNNNNNN.json
# Outputs: co-NNNNNNNN.json

load File.dirname(__FILE__) + "/../libs/utils.rb"

def reload
  load __FILE__
end

# Utility for converting a table row into hash values COGIS well information style
# Split table into fields according to <td>
# Further split when there are >= 5 &nbsp in a row

def fields_from_row(fields)
   # Further split on block of whitespace that contains at least 5 &nbsp; in a row
  fields = fields.flat_map do |field|
    ret = field.split(/[\s\u00A0]*\u00A0{5,}[\s\u00A0]*/)
    ret.empty? ? [""] : ret
  end
  
  # Clean up whitespace (trim begin, end, compress internal space)
  fields.map {|field| cleanup_web_text field}
end

# Convert fields to key-value pairs
# Loop over table fields:
# If table field contains ":" in the middle, it's a key/value pair
# Otherwise, if table field ends with ":", it's a key, and the next table field is the value

def hash_from_fields(fields)
  hash = {}
  key = nil

  fields.each do |field|
    if key
      # Assign to previously-found key
      hash[key] = field
      key = nil
    else
      (a,b) = field.split(":", 2)
      if b == ""
        # Field ends with colon; use as key for next field
        key = a.strip
      elsif b != nil
        # Field contains characters after colon; interpret as key=val
        hash[a] = b.strip
      end
    end
  end
  hash
end

# Handle <td> that aren't inside <tr>
def get_table_rows doc
  current_parent = nil
  rows = []
  doc.css("td,th").sort.each do |field|
    if field.text.include?("<![CDATA[")
      # skip
    elsif field.parent == current_parent
      rows[-1] << field.text
    else
      current_parent = field.parent
      rows << [field.text]
    end
  end
  rows
end

def add_fields_to_record!(record, add)
  initial = record.clone
  add.each do |key, value|
    if !record.has_key?(key)
      record[key] = value
    elsif record[key] == []
      # This is the first value encountered;  delete the key and reinsert so that
      # the order of fields in the hash matches the order encountered
      record.delete(key)
      record[key] = [value]
    elsif record[key].kind_of?(Array)
      record[key] << value
    else
      STDERR.puts "While adding #{add} to #{record} in add_fields_to_record!"
      raise "Duplicate key #{key} (consider seeding with empty array if expecting more than 1)"
    end
  end
  record
end

$rows = []
$ending_patterns = []

# Parse rows from $rows until empty, or first field of a row matches one of $ending_patterns
def parse(initial = {}, sections = {})
  ret = initial
  while !$rows.empty?
    fields = fields_from_row($rows[0])
    break if $ending_patterns.find {|pat| pat === fields[0]}
    #STDERR.puts fields.to_s
    $rows.shift
    hash = nil
    sections.each do |name, pattern|
      if pattern === fields[0]
        if name.kind_of?(Symbol)
          # This marks the end of a section.  Fall through
          # this loop and parse like normal
          break
        end
        # If pattern is a regular expression, create the Match structure to pass to the parser
        match = pattern.kind_of?(Regexp) && pattern.match(fields[0])
        save_ending_patterns = $ending_patterns
        $ending_patterns += sections.values
        hash = {name => send("parse_" + name.gsub(" ", "_"), fields, match)}
        $ending_patterns = save_ending_patterns
        break
      end
    end
    hash ||= hash_from_fields(fields)
    add_fields_to_record!(ret, hash)
  end
  ret
end

def parse_table(fields)
  table = [fields]
  while !$rows.empty?
    fields = fields_from_row($rows[0])
    break if $ending_patterns.find {|pat| pat === fields[0]}
    $rows.shift
    table << fields
  end
  array_to_hashes(table)
end

def parse_cogis(doc)
  $rows = get_table_rows doc
  ret = parse({},
              {"Surface Location Data" => /Surface Location Data for API # [\d-]+/})
  if ret.keys != ["Surface Location Data"]
    raise "parse_cogis got the wrong fields #{ret.keys}"
  end
  ret
end
  
def parse_Surface_Location_Data(fields, match)
  initial = hash_from_fields(fields[1..-1])
  initial["Wellbore Data for Sidetrack"] = []
  initial["FracFocus Disclosures"] = []
  parse(initial,
        {
          "Planned Location" => "Planned Location",
          "As Drilled Location" => "As Drilled Location",
          "FracFocus Disclosures" => /^Job Date: /,
          "Wellbore Data for Sidetrack" => /^Wellbore Data for Sidetrack #(\d+)$/
        })
end

def parse_Planned_Location(fields, match)
  hash_from_fields(["Footage:"] + fields[1..-1])
end

def parse_As_Drilled_Location(fields, match)
  hash_from_fields(["Footage:"] + fields[1..-1])
end

def parse_FracFocus_Disclosures(fields, match)
  hash_from_fields(fields)
end

def parse_Wellbore_Data_for_Sidetrack(fields, match)
  initial = {}
  initial["Sidetrack"] = match[1]
  initial = merge_hashes(initial, hash_from_fields(fields))
  initial["Status Date"] = fields[2]
  parse(initial,
        {
          "Wellbore Permit" => "Wellbore Permit",
          "Wellbore Completed" => "Wellbore Completed"
        });
end

def parse_Wellbore_Permit(fields, match)
  initial = {
    "Type" => fields[2],
    "Formation and Spacing" => [],
    "Casing" => [],
    "Cement" => [],
    "Additional Cement" => [],
  }
  parse(initial)
end

def parse_Wellbore_Completed(fields, match)
  initial = {
    "Log Types" => [],
    "Casing" => [],
    "Cement" => [],
    "Additional Cement" => [],
    "Completed information for formation" => [],
  }
  parse(initial,
        {
          "Top PZ Location" => /^Top PZ Location:.*(Sec:.*)?(Twp:.*)?$/,
#          "Top PZ Location" => /^Top PZ Location:.*(Sec:.*)(Twp:.*)$/,
          "Bottom PZ Location" => /^Bottom PZ Location:.*(Sec:.*)(Twp:.*)$/,
          "Bottom Hole Location" => /^Bottom Hole Location:.*(Sec:.*)(Twp:.*)$/,
          "Error" => /Location/, # flag other location fields we've missed
          "Formation" => "Formation",
          "Completed information for formation" => /^Completed information for formation (\S+)$/,
        })
end

def parse_Top_PZ_Location(fields, match)
  parse_location(fields, match)
end

def parse_Bottom_PZ_Location(fields, match)
  parse_location(fields, match)
end

def parse_Bottom_Hole_Location(fields, match)
  parse_location(fields, match)
end

def parse_Error(fields, match)
  STDERR.puts "While parsing fields #{fields}"
  raise "Parse error"
end

def parse_location(fields, match)
  fields = fields[1 .. -1]
  if match[2]
    fields = [match[2]] + fields
  end
  if match[1]
    fields = [match[1]] + fields
  end
  hash_from_fields(fields)
end

def parse_Formation(fields, match)
  parse_table(fields)
end

def parse_Completed_information_for_formation(fields, match)
  initial = {
    "Formation" => match[1],
    "Formation Treatment" => [],
  }
  parse(initial,
        {
          "Formation Treatment" => "Formation Treatment",
          :end_section => "Tubing Size:",   # This ends the Formation Treatment section, but doesn't itself start a section
          "Initial Test Data" => "Initial Test Data:",
          "Perforation Data" => "Perforation Data:",
        })
end

def parse_Formation_Treatment(fields, match)
  parse()
end

def parse_Initial_Test_Data(fields, match)
  parse({},
        {
          "Test Type" => "Test Type:"
        })
end

def parse_Test_Type(fields, match)
  parse_table(fields)
end

def parse_Perforation_Data(fields, match)
  parse()
end

def test
  $wells = read_json "data/co-unparsed-04515000.json"
  $well = $wells[15]  # has two sidebores
  $html = $well["unparsed_cogis"]
  $doc = nokogiri_doc $html
  parse_cogis($doc)
end

def main
  Dir.glob("data/co-unparsed-*.json").each do |unparsed|
    parsed = unparsed.sub("unparsed-", "")
    if File.exists?(parsed)
      STDERR.puts "#{parsed} already exists, skipping"
    else
      STDERR.write "Creating #{parsed} from #{unparsed} ... "
      errors = 0
      wells = read_json unparsed
      wells.each do |well|
        begin
          well["parsed_cogis"] = parse_cogis(nokogiri_doc(well["unparsed_cogis"]))
        rescue => e
          STDERR.puts "While processing well #{well["attrib_1"]}, COGIS URL http://cogcc.state.co.us/cogis/FacilityDetail.asp?facid=#{well["link_fld"]}&type=WELL"
          well["parsed_cogis"] = {"Parsing Error" => e.to_s}
          errors += 1
        end
      end
      write_json(parsed, wells)
      STDERR.puts "#{wells.size} wells (#{errors} parsing errors)"
    end
  end
end

main
