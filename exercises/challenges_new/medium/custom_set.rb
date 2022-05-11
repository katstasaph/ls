class CustomSet
  def initialize(arr = [])
    @elements = arr.uniq
  end
  
  def empty?
    elements.empty?
  end
  
  def contains?(element)
    elements.include?(element)
  end
  
  def subset?(other)
    elements.all? { |element| other.contains?(element) }
  end
  
  def intersection(other)
    self.class.new(elements.intersection(other.elements))
  end
  
  def union(other)
    self.class.new(elements.union(other.elements))
  end
  
  def difference(other)
    self.class.new(@elements - other.elements)
  end
  
  def disjoint?(other)
    intersection(other).empty?
  end
  
  def eql?(other)
    subset?(other) && other.subset?(self)
  end
  
  def add(new_element)
    new_set = self.dup
    new_set.elements << new_element unless contains?(new_element)
    new_set
  end
  
  def ==(other)
    eql?(other)
  end
  
  protected
  
  attr_reader :elements
end