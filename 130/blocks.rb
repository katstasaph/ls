def times(num)
  i = 1
  loop do
    yield(i)
    i += 1
    break if i > num
  end
  num
end

times(2) { |num| puts "#{num}" } 

def each(arr)
  i = 0
  loop do
    yield(arr[i])
    i += 1
    break if i > arr.length - 1
  end
  arr
end

p each([1, 2, 3]) { |num| puts "printing array element #{num}" }
p each([1, 2, 3, 4, 5]) {|num| "each test #2" }.select{ |num| num.odd? }

def select(arr)
  newarr = []
  each(arr) do |element|
    newarr << element if yield(element)
  end
  newarr
end

array = [1, 2, 3, 4, 5]

puts "select test #1"
p select(array) { |num| num.odd? }      # => [1, 3, 5]
puts "select test #2"
p select(array) { |num| puts num }      # => [], because "puts num" returns nil and evaluates to false
puts "select test #3"
p select(array) { |num| num + 1 }       # => [1, 2, 3, 4, 5], because "num + 1" evaluates to true

# we're not going to touch the extended functionality for now
def reduce(obj, accumulator = 0)
  each(obj) do |element|
    accumulator = yield(accumulator, element)
  end
  accumulator
end

p reduce(array) { |acc, num| acc + num }     # ==> 15
p reduce(array, 10) { |acc, num| acc + num }                # => 25
# reduce(array) { |acc, num| acc + num if num.odd? }        # => NoMethodError: undefined method `+' for nil:NilClass
