class Triangle
  attr_reader :side1, :side2, :side3

  def initialize(side1, side2, side3)
    raise ArgumentError.new("Invalid side lengths") unless valid?(side1, side2, side3)
    @side1 = side1
    @side2 = side2
    @side3 = side3
  end

  def kind
    return "equilateral" if side1 == side2 && side2 == side3
    return "scalene" if side1 != side2 && side1 != side3 && side2 != side3
    "isosceles"
  end
  
  private
  
  def valid?(s1, s2, s3)
    nonzero_sides?(s1, s2, s3) && triangle_inequality?(s1, s2, s3)
  end
  
  def nonzero_sides?(s1, s2, s3)
    s1 > 0 && s2 > 0 && s3 > 0
  end

  # no degenerate triangles i.e., s1 + s2 = s3
  def triangle_inequality?(s1, s2, s3) 
    (s1 + s2) > s3 && (s1 + s3) > s2 && (s2 + s3) > s1
  end
end