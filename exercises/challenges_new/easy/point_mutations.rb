class DNA
  attr_reader :strand

  def initialize(strand)
    raise ArgumentError unless valid?(strand)
    @strand = strand
  end
  
  def hamming_distance(other)
    return 0 if strand.empty? || other.empty?
    strand1 = strand.upcase.chars
    strand2 = other.upcase.chars
    distance = 0
    cutoff = [strand1.length, strand2.length].min - 1
    (0..cutoff).each do |index|
      distance += 1 if strand1[index] != strand2[index]
    end
    distance
  end
  
  private
  
  def valid?(strand)
    strand.class == String && strand.chars.all? { |chr| ['A', 'C', 'G', 'T'].include?(chr.upcase) }
  end
end