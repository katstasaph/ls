class Robot
  LETTERS = ("A".."Z").to_a
  NUMBERS = ("0".."9").to_a
  
  @@used_names = []
  
  def initialize
    @name = name
  end

  def name
    return @name if @name
    robot_name = ""
    2.times { robot_name += LETTERS.sample }
    3.times { robot_name += NUMBERS.sample }
    if @@used_names.include?(robot_name)
      robot_name = name
    else
      @@used_names << robot_name
    end
    @name = robot_name
  end
  
  def reset
    @@used_names.delete(@name)
    @name = nil
  end
end