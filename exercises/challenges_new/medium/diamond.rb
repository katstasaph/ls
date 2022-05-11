class Diamond
  START_LETTER = "A"

  def initialize
    @end_letter = nil
    @top_rows = nil
  end

  def self.make_diamond(end_letter)
    raise ArgumentError.new("Input must be a letter") unless valid?(end_letter)
    return "A\n" if end_letter == "A"
    @top_rows = (end_letter.upcase.ord - 64)
    @end_letter = end_letter
    rows_arr = produce_rows
    rows_arr += rows_arr[0..-2].reverse
    rows_arr.join()
  end
  
  class << self
    private
  
    def produce_rows
      rows_arr = []
      curr_letter = START_LETTER
      first_pos = last_pos = @top_rows - 1
      (1..@top_rows).each do |_|
        blank_row = clear_row
        blank_row[first_pos] = blank_row[last_pos] = curr_letter
        blank_row << "\n"
        rows_arr << blank_row.dup.join
        first_pos -= 1
        last_pos += 1
        curr_letter = curr_letter.succ
      end
      rows_arr
    end
  
    def clear_row
      Array.new(@top_rows * 2 - 1, " ")
    end
  
    def valid?(input)
      input.class == String && input.length == 1 && input.match(/[a-zA-Z]/)
    end
  end
end