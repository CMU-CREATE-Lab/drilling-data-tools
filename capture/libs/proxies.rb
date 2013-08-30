require "set"

# Scrapes hidemyass.com to yield publicly accessible HTTP proxies

class Proxies
  @@tried_proxies = Set.new
  @@untried_proxies = Set.new
  
  def self.get_untried_proxy
    if @@untried_proxies.empty?
      find_untried_proxies
    end
    if @@untried_proxies.empty?
      STDERR.puts "Out of untried proxies, aborting"
      exit 1
    end
    ret = @@untried_proxies.first
    @@untried_proxies.delete ret
    @@tried_proxies << ret
    ret
  end

  def self.find_untried_proxies
    # Grab proxy list
    html = open("http://hidemyass.com/proxy-list/",
                "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.71 Safari/537.36") {|f| f.read}

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
      ret
    end
    
    #STDERR.puts "Now: #{table_html}"
    # Filter out display:none 
    table_html.gsub!(/<[^>]*style\s*=\s*"[^"]*display\s*:\s*none[^"]*"[^>]*>[^<]*<[^>]*>/im, "");
    
    # Remove <style> ... </style>
    table_html.gsub!(/<style[^>]*>.*?<\/style[^>]*>/mi, "");
    
    proxies = table_to_hashes nokogiri_doc table_html
    proxies.each { |proxy| proxy["IP address"].gsub!(/\s/, "") }

    proxies.each do |proxy|
      if proxy["Type"] == "HTTP" && proxy["Connection time"].to_i > 20 && proxy["Speed"].to_i > 20
        url = "http://#{proxy["IP address"]}:#{proxy["Port"]}"
        if !@@tried_proxies.include? url
          @@untried_proxies << url
        end
      end
    end
  end
end
