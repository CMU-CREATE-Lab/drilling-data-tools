class Bounds
  attr_accessor :xmin, :ymin, :xmax, :ymax

  def initialize (xmin, ymin, xmax, ymax)
    @xmin = xmin
    @ymin = ymin
    @xmax = xmax
    @ymax = ymax
  end

  def split
    ret = 4.times.map {clone}
    ret[0].xmax = ret[1].xmin = ret[2].xmax = ret[3].xmin = 0.5 * (xmin + xmax)
    ret[0].ymax = ret[1].ymax = ret[2].ymin = ret[3].ymin = 0.5 * (ymin + ymax)
    ret
  end

  def area
    (xmax - xmin) * (ymax - ymin)
  end

  def to_hash
    {"xmin" => xmin, "ymin" => ymin, "xmax" => xmax, "ymax" => ymax}
  end

  def to_s
    "(#{xmin},#{ymin}) - (#{xmax},#{ymax})"
  end
end
