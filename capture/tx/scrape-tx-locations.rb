#!/usr/bin/env ruby2.0

require "json"
require "net/http"
require "rexml/document"
require "uri"

load File.dirname(__FILE__) + "/../libs/bounds.rb"

def fetch(layer, bounds)
  if bounds_area(bounds) > 400000000000
    # area too large
    return false
  end
  post_fields = {}
  post_fields[:ArcXMLRequest] = <<"EOF"
<?xml version="1.0"?>
<ARCXML version="1.1">
<REQUEST>
<GET_FEATURES outputmode="xml" geometry="false" featurelimit="1000" checkesc="false" envelope="false">
<LAYER id="#{layer}" />
<SPATIALQUERY subfields="#ALL#">
<SPATIALFILTER relation="area_intersection" >
<ENVELOPE minx="#{bounds['xmin']}" miny="#{bounds['ymin']}" maxx="#{bounds['xmax']}" maxy="#{bounds['ymax']}"/>
</SPATIALFILTER>
</SPATIALQUERY>
</GET_FEATURES>
</REQUEST>
</ARCXML>
EOF
  uri = URI("http://gis2.rrc.state.tx.us/arcims_sc/ims?ServiceName=simp&CustomService=Query&Form=True&Encode=True")
  req = Net::HTTP::Post.new uri
  req.form_data = post_fields
  Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.read_timeout = 3600
    http.request(req) do |response|
      response.code == "200" or raise "error in fetch: status #{response.code}"
      /XMLResponse='(.*?)'/.match response.body do |m|
        xml = URI.unescape(m[1].gsub("+", " ")).sub('encoding="ISO8859_1"', '').gsub('#SHAPE#=', 'SHAPE=')
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
    end
  end
  raise "error in fetch"
end

def collect(layer, bounds, nest = 0)
  elts = fetch(layer, bounds)
  if !elts
    STDERR.puts "#{"  " * nest}#{bounds}: too large; dividing"
    elts = split_bounds(bounds).flat_map {|bounds| collect(layer, bounds, nest + 1)}
  end
  STDERR.puts "#{"  " * nest}#{bounds}: #{elts.size} elements"
  elts
end

layer = 19 # well surface
#bounds = {"xmin"=>3000000, "ymin"=>3000000, "xmax"=>3200000, "ymax"=>3200000}
bounds = {"xmin"=>0, "ymin"=>0, "xmax"=>5000000, "ymax"=>5000000}
wells = collect(layer, bounds)
puts JSON.pretty_generate(wells)
