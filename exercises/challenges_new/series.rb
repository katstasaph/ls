class Series
  attr_reader :str
  def initialize(str)
    @str = str
  end
  
  def slices(amount) 
    raise ArgumentError if amount > str.length
    str.chars.map(&:to_i).each_cons(amount).to_a
  end
end
