class RomanNumeral
  LETTERS = ["M", "D", "C", "L", "X", "V", "I"]
  TEMPLATES = ["", "1", "11", "111", "12", "2", "21", "211", "2111", "13"]
  
  attr_reader :number

  def initialize(number)
    @number = number
  end

  def to_roman
    roman_str = ""
    digit_arr = digits(number)
    digit_arr.each_with_index do |digit, idx|
      place = digit_arr.length - idx
      roman_str += roman(digit, place)
    end
    roman_str
  end

  private
  
  def digits(num)
    digit_arr = []
    idx = (num.to_s.length) - 1
    while idx >= 0
      digit, num = num.divmod(10**idx)
      digit_arr << digit
      idx -= 1
    end
    digit_arr
  end
  
  def roman(digit, place)
    return ("M" * digit) if place == 4
    first = first_letter(place)
    second, third = next_letters(first)
    TEMPLATES[digit].gsub("1", first).gsub("2", second).gsub("3", third)
  end
  
  
  def first_letter(place)
    case place
    when 3 then "C"
    when 2 then "X"
    when 1 then "I"
    end
  end
  
  def next_letters(first)
    idx = LETTERS.index(first)
    [LETTERS[idx - 1], LETTERS[idx - 2]]
  end
end