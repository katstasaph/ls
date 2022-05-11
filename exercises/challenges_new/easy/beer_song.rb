class BeerSong
  def self.verse(num)
    self.verses(num)
  end

  def self.verses(first, last = first)
    song = ""
    nums = first.downto(last).to_a
    nums.each_with_index do |n, idx|
      song += "#{total(n)} #{bottles(n)} of beer on the wall, #{total(n)} #{bottles(n)} of beer.\n".capitalize
      if n > 0
        song += "Take #{one(n)} down and pass it around, #{total(n - 1)} #{bottles(n - 1)} of beer on the wall.\n"
      else
        song += "Go to the store and buy some more, 99 bottles of beer on the wall.\n"
      end
      song += "\n" if idx < nums.length - 1
    end
    song
  end
  
  def self.lyrics
    self.verses(99, 0)
  end
  
  class << self
    private
    
    def total(n)
      n == 0 ? "no more" : n
    end
    
    def bottles(n)
      n == 1 ? "bottle" : "bottles"
    end
    
    def one(n)
      n == 1 ? "it" : "one"
    end
  end
end