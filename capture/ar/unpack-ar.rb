#!/usr/bin/env ruby2.0

require 'fileutils'

def unpack_kml(kmzname)
  FileUtils.rm_f 'doc.kml'
  system "unzip #{kmzname}"
  kmlname = kmzname.sub(".kmz", ".kml")
  File.rename 'doc.kml', kmlname
  kmlname
end  

Dir.chdir 'data'

wells = unpack_kml 'Natural_Gas_and_Oil_Wells.kmz'
disposal = unpack_kml 'Drilling_Fluid_Disposal_Sites.kmz'

