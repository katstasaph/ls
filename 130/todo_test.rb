require "minitest/reporters"
require 'minitest/autorun'
Minitest::Reporters.use!

require_relative 'todo'

class TodoListTest < MiniTest::Test

  def setup
    @todo1 = Todo.new("Buy milk")
    @todo2 = Todo.new("Clean room")
    @todo3 = Todo.new("Go to gym")
    @todos = [@todo1, @todo2, @todo3]

    @list = TodoList.new("Today's Todos")
    @list.add(@todo1)
    @list.add(@todo2)
    @list.add(@todo3)
  end

  # Your tests go here. Remember they must start with "test_"

  def test_to_a
    assert_equal(@todos, @list.to_a)
  end
  
  def test_size
    assert_equal(3, @list.size)
  end
  
  def test_first
    assert_equal(@todo1, @list.first)
  end

  def test_last
    assert_equal(@todo3, @list.last)
  end

  def test_shift
    assert_equal(@todo1, @list.shift)
    assert_equal([@todo2, @todo3], @list.to_a)
  end

  def test_pop
    assert_equal(@todo3, @list.pop)
    assert_equal([@todo1, @todo2], @list.to_a)
  end
  
  def test_done?
    assert_equal(false, @list.done?)
    [@todo1, @todo2, @todo3].each { |todo| todo.done! }
    assert_equal(true, @list.done?)
  end

  def test_add_type_error
    assert_raises(TypeError) { @list << 2 }
    assert_raises(TypeError) { @list << nil }
  end

  def test_shovel
    new_todo = Todo.new("")
    @list << new_todo
    assert_includes(@list.to_a, new_todo)
  end
  
  def test_add
    new_todo = Todo.new("")
    @list.add(new_todo)
    assert_includes(@list.to_a, new_todo)
  end

  def test_item_at
    assert_equal(@todo1, @list.item_at(0))
    assert_raises(IndexError) { @list.item_at(5) }
  end

  def test_mark_done_at
    @list.mark_done_at(0)
    assert_equal(true, @todo1.done?)
    assert_equal(false, @todo2.done?)
    assert_equal(false, @todo3.done?)
    assert_raises(IndexError) { @list.mark_done_at(6) }
  end
  
  def test_mark_undone_at
    @todo1.done!
    @todo2.done!
    @todo3.done!
    @todo2.undone!
    @list.mark_undone_at(1)
    assert_equal(true, @todo1.done?)
    assert_equal(false, @todo2.done?)
    assert_equal(true, @todo3.done?)
    assert_raises(IndexError) { @list.mark_undone_at(6) }
  end

  def test_done!
    @todo1.done!
    @todo2.done!
    @todo3.done!
    assert_equal(true, [@todo1, @todo2, @todo3].all? { |todo| todo.done? })
    assert_equal(true, @list.done?)
  end
  
  def test_to_s
    output = <<~OUTPUT.chomp
---- Today's Todos ----
[ ] Buy milk
[ ] Clean room
[ ] Go to gym

OUTPUT
  assert_equal(output, @list.to_s)
  output = <<~OUTPUT.chomp
---- Today's Todos ----
[ ] Buy milk
[X] Clean room
[ ] Go to gym

OUTPUT
  @todo2.done!
  assert_equal(output, @list.to_s)
  @todo1.done!
  @todo3.done!
  output = <<~OUTPUT.chomp
---- Today's Todos ----
[X] Buy milk
[X] Clean room
[X] Go to gym

OUTPUT
  assert_equal(output, @list.to_s)
  end
  
  def test_each
    @list.each { |todo| todo.title = "Test" }
    assert_equal(true, [@todo1, @todo2, @todo3].all? { |todo| todo.title == "Test" })
    assert_equal(@list, @list.each { |todo| todo })
  end
  
  def test_select
    newlist = @list.select { |todo| todo.title == "Buy milk" }
    assert_equal(1, newlist.size)
    assert_equal(true, newlist.first == @todo1)
    assert_equal(false, newlist == @list)
  end

end