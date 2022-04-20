# This class represents a collection of Todo objects.
# You can perform typical collection-oriented actions
# on a TodoList object, including iteration and selection.

class TodoList
  attr_accessor :title

  def initialize(title)
    @title = title
    @todos = []
  end
  
  def add(todo)
    raise TypeError.new("Can only add Todo objects") unless todo.class == Todo
    @todos << todo
    self
  end
  
  alias << add

  # ---- Interrogating the list -----

  def size
    @todos.size
  end
  
  def first
    @todos.first
  end
  
  def last
    @todos.last
  end
  
  def to_a
    @todos.clone
  end
  
  def done?
    @todos.all? { |todo| todo.done? }
  end

  # ---- Iterating and selecting from the list -----  
  
  def each
    @todos.each { |todo| yield(todo) }
    self
  end
  
  def select
    selected = @todos.select { |todo| yield(todo) }
    selected.each_with_object(TodoList.new(title)) { |todo, list| list << todo }
  end

  def find_by_title(title)
    select { |todo| todo.title == title }.first
  end
  
  def all_done
    select { |todo| todo.done? }
  end
  
  def all_not_done
    select { |todo| !todo.done? }
  end  
  
  # ---- Retrieving an item in the list ----
  
  def item_at(position)
    @todos.fetch(position)
  end

  # ---- Marking items in the list -----
  
  def mark_done(title)
    each do |todo|
      if todo.title == title
        todo.done!
        return
      end
    end
  end
  
  def mark_done_at(position)
    @todos.fetch(position).done!
  end
  
  def mark_undone_at(position)
    @todos.fetch(position).undone!
  end
  
  def mark_all_done
    each { |todo| todo.done! }
  end
  
  alias done! mark_all_done
  
  def mark_all_undone
    each { |todo| todo.undone! }
  end

  # ---- Deleting from the list -----
  
  def shift
    @todos.shift
  end
  
  def pop
    @todos.pop
  end
  
  def remove_at(position)
    @todos.fetch(position)
    @todos.delete_at(position)
  end

  # ---- Outputting the list -----

  def to_s
    "---- Today's Todos ----\n" + @todos.map { |todo| todo.to_s + "\n"}.join
  end
  
end

# This class represents a todo item and its associated
# data: name and description. There's also a "done"
# flag to show whether this todo item is done.

class Todo
  DONE_MARKER = 'X'
  UNDONE_MARKER = ' '

  attr_accessor :title, :description, :done

  def initialize(title, description='')
    @title = title
    @description = description
    @done = false
  end

  def done!
    self.done = true
  end

  def done?
    done
  end

  def undone!
    self.done = false
  end

  def to_s
    "[#{done? ? DONE_MARKER : UNDONE_MARKER}] #{title}"
  end

  def ==(otherTodo)
    title == otherTodo.title &&
      description == otherTodo.description &&
      done == otherTodo.done
  end
end

# https://web.archive.org/web/20200125023057/http://www.listsofnote.com/2011/12/smells-like-teen-spirit.html
todo1 = Todo.new("Mercedes benz and a few old cars")
todo2 = Todo.new("Access to a abandoned mall, main floor and one Jewelry shop")
todo3 = Todo.new("lots of fake Jewelry")
todo4 = Todo.new("School Auditorium (Gym)")
todo5 = Todo.new("A cast of hundreds. 1 custodian, students")
todo6 = Todo.new("6 black Cheerleader outfits with Anarchy A's on chest")

todo_list = TodoList.new("To Do")

todo_list.add(todo1)
todo_list << todo2
todo_list << todo3
todo_list << todo4
todo_list << todo5
todo_list << todo6
puts todo_list
todo_list.mark_done_at(1)
puts todo_list
todo_list.mark_undone_at(1)
puts todo_list
todo_list.done!
puts todo_list
todo_list.remove_at(4)
puts todo_list

todo_list.each do |todo|
  puts "needed: #{todo}"
end

puts "\n"
todo_list.mark_undone_at(2)
todo_list.mark_undone_at(1)
results = todo_list.select { |todo| todo.done? } 
puts results

p todo_list.find_by_title("Mercedes benz and a few old cars")
p todo_list.find_by_title("entertain us")
puts todo_list.all_done
puts todo_list.all_not_done
todo_list.mark_done("lots of fake Jewelry")
puts todo_list
todo_list.mark_all_undone
puts todo_list