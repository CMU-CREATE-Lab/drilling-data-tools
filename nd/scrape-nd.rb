#!/usr/bin/env ruby2.0

require "net/http"
require "uri"
require "rexml/document"
require "json"

load File.dirname(__FILE__) + "/../libs/utils.rb"
load File.dirname(__FILE__) + "/../libs/bounds.rb"

def reload
  load __FILE__
end

def fetch(layer, bounds)
  if bounds.area > 400000000000
    # area too large
    return false
  end
  post_fields = {}
  post_fields["ArcXMLRequest"] = <<"EOF"
<?xml version="1.0"?>
<ARCXML version="1.1">
<REQUEST>
<GET_FEATURES outputmode="xml" geometry="false" featurelimit="1000" checkesc="false" envelope="false">
<LAYER id="#{layer}" />
<SPATIALQUERY subfields="#ALL#">
<SPATIALFILTER relation="area_intersection" >
<ENVELOPE minx="#{bounds.xmin}" miny="#{bounds.ymin}" maxx="#{bounds.xmax}" maxy="#{bounds.ymax}"/>
</SPATIALFILTER>
</SPATIALQUERY>
</GET_FEATURES>
</REQUEST>
</ARCXML>
EOF

  # Ruby doesn't have the right SSL certificate, and isn't robust to lack of correctly formatted status msg.  curl to the rescue
  response = `curl -s 'https://www.dmr.nd.gov/servlet/com.esri.esrimap.Esrimap?ServiceName=TestSDE&CustomService=Query&ClientVersion=4.0&Form=True&Encode=True' -d '#{URI.encode_www_form post_fields}'`
  /XMLResponse='(.*?)'/.match response do |m|
    xml = URI.unescape(m[1].gsub("+", " ")).sub('encoding="ISO8859_1"', '').gsub('#SHAPE#=', 'SHAPE=')
    # Surgery: fix lack of quoting in the value
    xml.gsub!(/(ogd[\w\.]+=")(.*?)(" (sde10|SHAPE|\/>))/) do
      a = $1
      b = $2
      c = $3
      b.gsub!("&", "&amp;")
      b.gsub!('"', "&quot;")
      a + b + c
    end
    doc = REXML::Document.new xml
    if doc.elements["ARCXML/RESPONSE/FEATURES/FEATURECOUNT"].attributes['hasmore'] == "true"
      # Too many elements
      return false
    end
    elts = []
    doc.elements.each("ARCXML/RESPONSE/FEATURES/FEATURE/FIELDS") do |feature|
      elt = {}
      feature.attributes.each_attribute {|attr| elt[attr.expanded_name] = attr.value}
      elts << elt
    end
    return elts
  end
  raise "error in fetch"
end

def collect(layer, bounds, nest = 0)
  elts = fetch(layer, bounds)
  if !elts
    STDERR.puts "#{"  " * nest}#{bounds}: too large; dividing"
    elts = bounds.split.flat_map {|bounds| collect(layer, bounds, nest + 1)}
  end
  STDERR.puts "#{"  " * nest}#{bounds}: #{elts.size} elements"
  elts
end

def main
  layer = 52 # well surface
  #bounds = Bounds.new(250000,5093750.0, 290625.0,5125000.0)
  bounds = Bounds.new(250000, 5000000, 900000, 5500000)
  wells = collect(layer, bounds)
  write_json("data/nd.json", wells)
end

main
