def write_kml(filename, placemarks)
  begin
    Dir.mkdir File.dirname(filename)
  rescue
  end
  open(filename+".tmp", "w") do |out|
    out.puts '<?xml version="1.0" encoding="UTF-8"?>'
    out.puts '<kml xmlns="http://www.opengis.net/kml/2.2"><Document>'
    placemarks.each do |placemark|
      out.puts "<Placemark><description>#{placemark["description"]}</description><Point><coordinates>#{placemark["lon"]},#{placemark["lat"]},0</coordinates></Point></Placemark>"
    end
    out.puts '</Document></kml>'
  end
  File.rename filename+".tmp", filename
  STDERR.puts "Wrote #{placemarks.size} placemarks to #{filename}"
end

