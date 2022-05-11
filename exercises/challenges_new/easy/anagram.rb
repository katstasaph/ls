class Anagram
  attr_reader :word
  
  def initialize(word)
    @word = word.downcase
  end
  
  def match(candidates)
    letters = word.chars.sort
    candidates.select do |candidate| 
      candidate = candidate.downcase
      candidate != word && candidate.chars.sort == letters
    end
  end

end