class Scrabble
  SCORES = {
    1 => ["A", "E", "I", "O", "U", "L", "N", "R", "S", "T"],
    2 => ["D", "G"],
    3 => ["B", "C", "M", "P"],
    4 => ["F", "H", "V", "W", "Y"],
    5 => ["K"],
    8 => ["J", "X"],
    10 => ["Q", "Z"]
  }
  attr_reader :word
  
  def initialize(word)
    @word = word
  end
  
  def self.score(word)
    self.new(word).score
  end
  
  def score
    return 0 unless word.class == String
    letters = word.upcase.chars
    letters.inject(0) do |total, letter|
      amount = value(letter)
      total + amount
    end
  end
  
  private
  
  def value(letter)
    SCORES.values.each do |letters|
      return SCORES.key(letters) if letters.include?(letter)
    end
    0
  end
end