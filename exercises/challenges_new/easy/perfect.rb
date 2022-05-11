class PerfectNumber
  def self.classify(input)
    raise StandardError.new("Must be a positive number") unless natural_number?(input)
    aliquot = divisors(input).inject(:+)
    if aliquot > input
      "abundant"
    elsif aliquot < input
      "deficient"
    else
      "perfect"
    end
  end

  class << self
    private

    def natural_number?(input)
      input.class == Integer && input > 0
    end
  
    def divisors(n)
      divisors = [1]
      (2..Math.sqrt(n)).each do |num|
        if n % num == 0
          divisors << num
          divisors << n / num unless num == Math.sqrt(n)
        end
      end
      divisors
    end
  end
end