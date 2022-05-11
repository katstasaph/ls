require 'date'

class Meetup
  DAY_INDEXES = {"Sunday" => 0,
  "Monday" => 1,
  "Tuesday" => 2,
  "Wednesday" => 3,
  "Thursday" => 4,
  "Friday" => 5,
  "Saturday" => 6 }  
  
  DAY_ORDINALS = {"first" => 0,
  "second" => 1,
  "third" => 2,
  "fourth" => 3,
  "fifth" => 4 }

  def initialize(year, month)
    @year = year
    @month = month
  end

  def day(day_of_week, ordinal)
    day_of_week = day_of_week.capitalize
    ordinal = ordinal.downcase
    case ordinal
    when "teenth" then teenth(day_of_week)
    when "last" then last(day_of_week)
    else find_day(day_of_week, ordinal)
    end
  end
  
  private
  
  def teenth(day_of_week)
    date = Date.civil(@year, @month, 13)
    find_day_in_week(day_of_week, date)
  end
 
  def last(day_of_week)
    date = Date.civil(@year, @month, 1)
    start = find_day_in_week(day_of_week, date)
    while (start + 7).month == @month
      start += 7
    end
    start
  end
 
  def find_day(day_of_week, ordinal)
    date = Date.civil(@year, @month, 1)
    start = find_day_in_week(day_of_week, date)
    start += (7 * DAY_ORDINALS[ordinal])
    start.month == @month ? start : nil
  end
  
  def find_day_in_week(day_of_week, date)
    loop do
      break if date.wday == DAY_INDEXES[day_of_week]
      date += 1
    end
    date
  end
 
end