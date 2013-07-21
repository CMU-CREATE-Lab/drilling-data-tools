#!/usr/bin/env ruby2.0

require "nokogiri"
load File.dirname(__FILE__) + "/../libs/utils.rb"

# curl 'http://wogcc.state.wy.us/wellstr.cfm?wellinfo=apino,county,Permit,qtr1,qtr2,sec,twp,t_dir,rge,r_dir,status,Lat,Lon,WELL_CLASS,STATDAY,STATMONTH,STATYEAR,Wn,Unit_lease,COMPANY,LEASE_NO,FIELD_NAME,LAND_TYPE,FOOT1,FOOT2,MEAS_FROM,ELEV,ELEVKB,TD,PB,BOTFORM,UNIT_CODE,LOT_TRACT,Bqtr1,Bqtr2,Bsec,Btwp,Bt_dir,Brge,Br_dir,BFOOT1,BFOOT2,BLON,BLAT,Form2stat,Form2Mon,Form2Year&Cato=N&Prod=Y&requestTimeOut=15000&twp=12&rge=62' 

# http://wogcc.state.wy.us/wyodall.cfm?nAPINO=1320535&nApi=1320535&Oops=

def reload
  load __FILE__
end

def fetch_well_summaries(township, range)
  url = "http://wogcc.state.wy.us/wellstr.cfm?wellinfo=apino,county,Permit,qtr1,qtr2,sec,twp,t_dir,rge,r_dir,status,Lat,Lon,WELL_CLASS,STATDAY,STATMONTH,STATYEAR,Wn,Unit_lease,COMPANY,LEASE_NO,FIELD_NAME,LAND_TYPE,FOOT1,FOOT2,MEAS_FROM,ELEV,ELEVKB,TD,PB,BOTFORM,UNIT_CODE,LOT_TRACT,Bqtr1,Bqtr2,Bsec,Btwp,Bt_dir,Brge,Br_dir,BFOOT1,BFOOT2,BLON,BLAT,Form2stat,Form2Mon,Form2Year&Cato=N&Prod=Y&requestTimeOut=15000&twp=#{township}&rge=#{range}"
  html = fetch_url url
  
  # Reconstructive surgery:  third and later rows don't have <tr> open, so replace "</tr> <td" with "</tr><tr><td"
  html.gsub!(/<\/tr>\s*<td/im, "</tr>\n<tr><td"); nil
  doc = Nokogiri::HTML(html) {|config| config.strict.nonet}
  table_to_hashes(doc)
end

def fetch_well_detail_html(api)
  fetch_url "http://wogcc.state.wy.us/wyodall.cfm?nAPINO=#{api}&nApi=#{api}&Oops="
end

def fetch_wells(township, range)
  wells = fetch_well_summaries(township, range)
  STDERR.write "Reading details from #{wells.size} wells "
  ticks = Ticks.every 10
  wells.each do |well|
    well["detail_html"] = fetch_well_detail_html(well["Api Number"])
    sleep 0.5
    ticks.increment
  end
  wells
end

def main
  $fetch_url_use_proxy = true
  townships = (12 .. 58)
  townships.each do |township|
    (60 .. 121).each do |range|
      filename = sprintf("data-unparsed/wy-t%03d-r%03d.json", township, range)
      if File.exists? filename
        STDERR.puts "#{filename} already exists, skipping"
      else
        STDERR.write "Creating #{filename}; "
        wells = fetch_wells(township, range)
        write_json(filename, wells)
        STDERR.write "done (#{wells.size} wells)\n"
        sleep 5
      end
    end
    STDERR.puts "Completed township #{township} #{(100.0 * ((township + 1) - townships.min) / townships.size).round}%"
  end
end

main

