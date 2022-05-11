class SimpleLinkedList
  attr_reader :head

  def initialize
    @head = nil
  end
  
  def self.from_a(arr = [])
    list = new
    unless arr.nil?
      arr.reverse.each { |element| list.push(element) }
    end
    list
  end
  
  def push(datum)
    element = Element.new(datum, head)
    @head = element
  end
  
  def pop
    popped = head
    @head = head.next
    popped.datum
  end
  
  def peek
    head ? head.datum : nil
  end
  
  def size
    elements = 0
    current_element = head
    while !!current_element
      elements += 1
      current_element = current_element.next
    end
    elements
  end
  
  def empty?
    size == 0
  end
  
  def to_a
    arr = []
    element = head
    size.times do
      arr << element.datum
      element = element.next
    end
    arr
  end
  
  def reverse
    self.class.from_a(to_a.reverse)
  end
end

class Element
  attr_reader :datum, :next
  def initialize(datum = nil, next_ref = nil)  
    @datum = datum
    @next = next_ref
  end
  
  def tail?
    !@next
  end
end