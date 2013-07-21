# Represents range of dates from

class DateRange
  attr_accessor :from, :to
  
  def initialize (from, to)
    @from = from
    @to = to
  end

  def split
    duration < 2 and raise "Short DateRange cannot be split"
    midpoint = from + duration / 2
    [DateRange.new(from, midpoint), DateRange.new(midpoint, to)]
    #puts "Split #{self} into #{ret[0]}, #{ret[1]}"
  end

  def duration
    to - from
  end

  def to_s
    "#{from.strftime("%m/%d/%Y")}-#{to.strftime("%m/%d/%Y")}"
  end
end
