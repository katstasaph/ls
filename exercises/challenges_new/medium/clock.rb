class Clock
  DAY_PERIOD = 1440
  MINUTES_IN_HOUR = 60
  
  def initialize(minutes)
    @minutes = minutes
  end
  
  def self.at(hours, minutes = 0)
    minutes = (hours * MINUTES_IN_HOUR) + minutes
    new(minutes)
  end
  
  def +(mins)
    @minutes += mins
    normalize
    self
  end
  
  def -(mins)
    self + (-mins)
  end
  
  def ==(other)
    minutes == other.minutes
  end

  def to_s
    hours, mins = minutes.divmod(MINUTES_IN_HOUR)
    format('%02d:%02d', hours, mins)
  end
  
  protected
  
  attr_reader :minutes

  private
  
  def normalize
    positive = minutes > 0
    loop do
      if minutes >= 0 && minutes < DAY_PERIOD
        break
      end
    positive ? @minutes -= DAY_PERIOD : @minutes += DAY_PERIOD
    end
  end
end