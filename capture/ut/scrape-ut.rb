#!/usr/bin/env ruby2.0

load File.dirname(__FILE__) + "/../libs/utils.rb"

def reload
  load __FILE__
end

def fetch_wells(url, fields, min=4300000000, max=4305900000, indent = 0)
  if (max - min) > 10000
    need_to_split = true
  else
    fields["search0"] = "#{min},#{max}"
    html = post(url, fields);
    if html =~ /Things did not go as planned/
      STDERR.puts "Error fetching wells"
      exit 1
    end
    need_to_split = (html =~ /Next 200/)
  end
  # Too many results
  if need_to_split
    STDERR.puts ("  " * indent) + "Wells #{min}-#{max} is too big; splitting into two requests"
    mid = (min + max) / 2
    wells = fetch_wells(url, fields, min, mid, indent + 1) + fetch_wells(url, fields, mid, max, indent + 1)
  else
    doc = nokogiri_doc html
    wells = table_to_hashes widest_table doc
  end
  STDERR.puts ("  " * indent) + "API #{min}-#{max} has #{wells.size} wells"
  wells
end

def write_wells(dest, url, fields)
  if File.exists? dest
    STDERR.puts "#{dest} already exists, skipping"
  else
    STDERR.puts "Creating #{dest}"
    wells = fetch_wells(url, fields)
    write_json dest, wells
    STDERR.puts "Wrote #{wells.size} records to #{dest}"
  end
end

def write_info
  write_wells("ut-info.json",
              "http://oilgas.ogm.utah.gov/Data_Center/LiveData_Search/well_data_lookup.cfm",
              {
                "column0" => "API_WellNo",
                "ref0" => "BETWEEN",
                "PageNum_wells" => "1",
                "rev" => "",
                "ord" => "ASC",
                "sort" => "API_WellNo",
                "loop" => "0"
              })
end

def write_history
  write_wells("ut-history.json",
              "http://oilgas.ogm.utah.gov/Data_Center/LiveData_Search/well_history_lookup.cfm",
              {
                "column0" => "Web_tblWellMaster.API_WellNo",
                "ref0" => "BETWEEN",
                "PageNum_wellhistory" => "1",
                "rev" => "",
                "ord" => "ASC",
                "sort" => "Web_tblHistory.API_WellNo",
                "loop" => "0"
              })
end
  
def write_formations
  write_wells("ut-formations.json",
              "http://oilgas.ogm.utah.gov/Data_Center/LiveData_Search/well_form_lookup.cfm",
              {
                "column0" => "API_WellNo",
                "ref0" => "BETWEEN",
                "PageNum_wellform" => "1",
                "rev" => "",
                "ord" => "ASC",
                "sort" => "API_WellNo",
                "loop" => "0"
              })
end

def write_permits
  write_wells("ut-permits.json",
              "http://oilgas.ogm.utah.gov/Data_Center/LiveData_Search/APD_lookup.cfm",
              {
                "column0" => "API",
                "ref0" => "BETWEEN",
                "PageNum_permit" => "1",
                "ord" => "ASC",
                "sort" => "APD_POST_DATE",
                "loop" => "0"
              })
end

def write_spuds
  write_wells("ut-spuds.json",
              "http://oilgas.ogm.utah.gov/Data_Center/LiveData_Search/Spud_lookup.cfm",
              {
                "column0" => "api",
                "ref0" => "BETWEEN",
                "PageNum_spud" => "1",
                "rev" => "",
                "ord" => "ASC",
                "sort" => "spuddate",
                "loop" => "0"
              })
end

def write_completions
  write_wells("ut-completions.json",
              "http://oilgas.ogm.utah.gov/Data_Center/LiveData_Search/WCR_lookup.cfm",
              {
                "column0" => "api",
                "ref0" => "BETWEEN",
                "PageNum_WCR" => "1",
                "ord" => "ASC",
                "sort" => "compl_date_wcr",
                "loop" => "0"
              })
end

def write_logs
  write_wells("ut-logs.json",
              "http://oilgas.ogm.utah.gov/Data_Center/LiveData_Search/scan_data_lookup.cfm",
              {
                "column0" => "Web_tblWellMaster.API_WellNo",
                "ref0" => "BETWEEN",
                "PageNum_scans" => "1",
                "rev" => "",
                "ord" => "ASC",
                "sort" => "Web_tblScanLogs.API_WellNo",
                "loop" => "0"
              })
end

def main
  write_info
  write_history
  write_formations
  write_permits
  write_spuds
  write_completions
  write_logs
end

main
