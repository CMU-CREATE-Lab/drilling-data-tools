$browser = nil

require "watir-webdriver"

def browser
  if not $browser
    $download_dir = "/tmp/downloads.#{Etc.getlogin}.#{Process.pid}"
    puts "Download dir is #{$download_dir}"
    clear_downloads
    profile = Selenium::WebDriver::Firefox::Profile.new
    profile['browser.download.folderList'] = 2
    profile['browser.download.dir'] = $download_dir
    profile['browser.helperApps.neverAsk.saveToDisk'] = "application/vnd.ms-excel"
    profile['browser.helperApps.alwaysAsk.force'] = false;
    $browser = Watir::Browser.new :firefox, :profile => profile
#    profile = Selenium::WebDriver::Chrome::Profile.new
#    profile['download.prompt_for_download'] = false
#    profile['download.default_directory'] = $download_dir
#    $browser = Watir::Browser.new :chrome, :profile => profile
  end
  $browser
end

def download 
  clear_downloads
  yield
  read_download
end
  
def clear_downloads
  Dir.glob("#{$download_dir}/*").each do |filename|
    begin
      File.delete filename
    rescue
    end
  end
end    

def read_download
  # Firefox creates dest and dest.part simultaneously, so there are 2 files while
  # downloading.  Wait until there's just one, then return its contents
  #puts "Waiting for download to #{$download_dir}"
  retries = 0
  while true
    # sleep before first check to hopefully avoid race when FF creates both 
    # dest and dest.part.
    sleep 0.1 
    files = Dir.glob("#{$download_dir}/*")
    if files.size == 1
      file = files[0]
      size = File.size? file
      if retries < 10 && (File.extname(file) == ".part" || !size || size == 0)
        # Suspiciously like we're in the middle of a race.  Keep trying for a while
        retries += 1
      else
        ret = open(files[0]) {|f| f.read}
        #puts "Read #{ret.size} bytes from #{files[0]}; deleting"
        File.delete files[0]
        return ret
      end
    elsif files.size > 2
      raise "Extra junk in #{$download_dir}: #{files.join("|")};  please call clear_downloads before downloading"
    end
  end
end
