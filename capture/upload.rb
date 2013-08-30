#!/usr/bin/env ruby2.0

Dir.glob("*/data").each do |dir|
  dest = "/usr0/web/randy-public/drillviz/#{dir}"
  cmd = "ssh g7 mkdir -p #{dest}; rsync -av #{dir}/ g7:#{dest} &"
  puts cmd
  system cmd
end
