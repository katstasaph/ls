class SumOfMultiples
  attr_reader :multiples

  def initialize(*multiples)
    if multiples.empty? then multiples = [3, 5] end
    @multiples = multiples
  end

  def self.to(limit)
    SumOfMultiples.new.to(limit)
  end

  def to(limit)
    mults = (1...limit).select do |n|
      multiple?(n)
    end
    mults.empty? ? 0 : mults.inject(:+)
  end
  
  private
  
  def multiple?(num)
    multiples.any? { |n| num % n == 0 }
  end
  
end