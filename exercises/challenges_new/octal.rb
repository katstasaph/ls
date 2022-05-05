class Octal
  attr_reader :number
  
  def initialize(number)
    @number = number
  end
  
  def to_decimal
    return 0 if invalid?(number)
    sum = 0
    num_digits = number.to_i.digits
    num_digits.each_with_index do |digit, i|
      amount = digit * 8**i
      sum += amount
    end
    sum
  end

  private
  
  def invalid?(num)
    num.count("^0-7") > 0
  end
end