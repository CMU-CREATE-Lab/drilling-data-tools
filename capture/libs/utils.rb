require "json"
require "net/http"
require "nokogiri"
require "open-uri"
require "openssl"

load File.dirname(__FILE__) + "/proxies.rb"

def write_json(filename, obj)
  begin
    Dir.mkdir File.dirname(filename)
  rescue
  end
  open(filename+".tmp", "w:UTF-8") {|out| out.puts JSON.pretty_generate(obj)}
  File.rename filename+".tmp", filename
  STDERR.puts "Wrote #{obj.size} records to #{filename}"
end

# if top-level obj is array, splits each elt onto a separate line;  otherwise, everything on a single line
def write_compact_json(filename, obj)
  begin
    Dir.mkdir File.dirname(filename)
  rescue
  end
  open(filename+".tmp", "w:UTF-8") do |out| 
    if obj.kind_of?(Array)
      out.puts '['
      obj.each_with_index do |e, i|
        out.write JSON.generate(e)
        out.write (i < obj.size - 1) ? ",\n" : "\n"
      end
      out.puts ']'
    else
      out.puts JSON.generate(obj)
    end
    File.rename filename+".tmp", filename
  end
  STDERR.puts "Wrote #{obj.size} records to #{filename}"
end

def read_json(filename)
  open(filename, "r:UTF-8") do |f| 
    ret = JSON.parse(f.read)
    STDERR.puts "Read #{ret.size} records from #{filename}"
    ret
  end
end

class Ticks
  attr_accessor :period, :count
  def self.every(period)
    Ticks.new(period)
  end
  def initialize(period)
    @period = period
    @count = 0
    STDERR.write " #{period}x:"
  end
  def increment
    if (@count += 1) % period == 0
      STDERR.write "."
    end
  end
end

# nokogiri utils

def cleanup_web_text(text)
  text = text.gsub("\u00A0", " ")  # convert non-blocking unicode space to space
  text = text.strip # Remove leading and trailing whitespace
  text.gsub(/\s+/, " ") # Convert all runs of whitespace into single spaces
end

def cleanup_field_name(text)
  text.gsub(/\s+/, " ")
end
  
def table_to_array(table)
  $table = table
  table.css("tr").map do |row| 
    row.css("th,td").flat_map do |e| 
      ret = [cleanup_web_text(e.text)]
      # If colspan is set and > 1, insert blank columns
      if e.attributes["colspan"]
        (e.attributes["colspan"].value.to_i - 1).times { ret << "" }
      end
      ret
    end
  end
end

def table_to_hashes(table)
  array_to_hashes(table_to_array(table))
end

def array_to_hashes(table_array)
  if table_array.size < 2
    return []
  end
  fieldnames = table_array.shift.map {|f| cleanup_field_name(f)}
  fieldnames.size.times do |i|
    (i + 1 .. fieldnames.size).each do |j|
      # Replace any empty strings with prev non-empty field name followed by 2, 3, ...
      if fieldnames[j] != ""
        break
      end
      fieldnames[j] = "#{fieldnames[i]} #{j - i + 1}"
    end
  end
  table_array.map {|row| Hash[*fieldnames.zip(row).flatten]}
end

$fetch_url_count = 0
$fetch_url_use_proxy = false;
$fetch_url_current_proxy = false;
$fetch_retry_on_error = false;

def fetch_url(url)
  while true
    begin
      $fetch_url_count += 1
      open(url,
           "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.71 Safari/537.36",
           :proxy => $fetch_url_current_proxy) do |f|
        return f.read
      end
    rescue => e
      STDERR.puts "\n\Exception '#{e}' while fetching #{url} (fetch # #{$fetch_url_count})\n"
      if $fetch_retry_on_error
        STDERR.puts "Sleeping #{$fetch_retry_on_error} seconds and retrying"
        sleep $fetch_retry_on_error
      elsif $fetch_url_use_proxy
        $fetch_url_current_proxy = Proxies.get_untried_proxy
        STDERR.puts "Switching to proxy #{$fetch_url_current_proxy}"
      else
        STDERR.puts "If you're being blocked, consider setting $fetch_url_use_proxy = true"
        exit 1
      end
    end
  end
end

def post(url, args)
  response = Net::HTTP.post_form(URI.parse(url), args)
  if response.code == "200"
    return response.body
  else
    STDERR.puts "Form post to #{url} with args #{args} failed with response code #{response.code}"
    exit 1
  end
end

def nokogiri_doc(html)
  Nokogiri::HTML(html) {|config| config.strict.nonet}
end

def widest_row(table)
  table.css("tr").max_by {|row| row.css("td,th").size}
end

def widest_table(doc)
  doc.css("table").max_by {|table| widest_row(table).css("td,th").size}
end

def get_proxies()
  # Grab proxy list
  #html = fetch_url("http://www.hidemyass.com/proxy-list/")
  html = $html
  doc = nokogiri_doc html
  # Get the table
  table = widest_table doc

  table_html = table.to_s

  # Unwrap connection speeds and times
  table_html.gsub!(/<div[^>]*style="width:(\d+)%"[^>]*>\s*<\/div>/im) { $1 }

  # Apply display styles
  styles = {}
  
  table_html.gsub!(/\.([\w-]+){display:(\w+)}|class="([^"]+)"/mi) do
    ret = if $3
            styles[$3] ? "style=\"display:#{styles[$3]}\"" : ""
          else
            styles[$1] = $2
            $&
          end
    #STDERR.puts "Replacing '#{$&}' with '#{ret}'"
    ret
  end

  #STDERR.puts "Now: #{table_html}"
  # Filter out display:none 
  table_html.gsub!(/<[^>]*style\s*=\s*"[^"]*display\s*:\s*none[^"]*"[^>]*>[^<]*<[^>]*>/im, "");

  # Remove <style> ... </style>
  table_html.gsub!(/<style[^>]*>.*?<\/style[^>]*>/mi, "");

  #STDERR.puts "Now: #{table_html}"
  #STDERR.puts "Text: #{nokogiri_doc(table_html).text}"
  proxies = table_to_hashes nokogiri_doc table_html
  proxies.each { |proxy| proxy["IP address"].gsub!(/\s/, "") }
  ret = []
  proxies.each do |proxy|
    if proxy["Type"] == "HTTP" && proxy["Connection time"].to_i > 20 && proxy["Speed"].to_i > 20
      ret << "http://#{proxy["IP address"]}:#{proxy["Port"]}"
    end
  end
  ret
end

# Warn if dup field
def merge_hashes(a, b)
  b.each do |key, value|
    if a.has_key? key
      raise "Duplicate key #{key} when merging hashes"
    end
  end
  a.merge b
end

