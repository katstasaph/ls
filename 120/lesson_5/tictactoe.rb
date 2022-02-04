require 'yaml'
PROMPTS = YAML.load_file('tictactoe.yml')

module Output
  def prompt(input)
    puts ">> #{input}"
  end

  def newline
    puts "\n"
  end

  def clear_screen
    system "clear"
  end

  def pause
    prompt PROMPTS["enter"]
    gets
    clear_screen
  end

  def join_with_or(arr)
    newarr = arr.map { |num| (num.to_s) + "," }
    if newarr.length > 1
      if newarr.length == 2 then newarr[-2].delete_suffix(",") end
      newarr[-2] += " or"
    end
    newarr[-1] = newarr[-1].delete_suffix(",")
    newarr.join(" ")
  end
end

module Input
  YESNO = { "y" => "yes", "n" => "no" }

  def prompt_yes_or_no
    input = nil
    loop do
      input = gets.strip.downcase
      break if valid_input?(input, YESNO)
      prompt PROMPTS["yesno"]
    end
    input
  end

  def yes?(input)
    input == "y" || input == "yes"
  end

  def no?(input)
    input == "n" || input == "no"
  end

  def valid_input?(input, valid_inputs)
    valid_inputs.keys.include?(input) || valid_inputs.values.include?(input)
  end

  def valid_positive_int?(input)
    input.to_i.to_s == input && input.to_i > 0
  end

  def prompt_integer
    total = nil
    loop do
      total = gets.strip
      break if valid_positive_int?(total)
      prompt PROMPTS["invalid_number"]
    end
    total.to_i
  end
end

class Board
  include Output

  DIVIDER_ROW = "-----------"
  FILLER_ROW = "   |   |   "
  EMPTY = " "
  ALL_KEYS = (1..9)
  ALL_ROWS = (1..13)
  WINNING_LINES = [
    [1, 2, 3], [4, 5, 6], [7, 8, 9], [1, 4, 7],
    [2, 5, 8], [3, 6, 9], [1, 5, 9], [3, 5, 7]
  ]

  attr_accessor :squares, :symbols

  def initialize
    @squares = {}
  end

  def display
    ALL_ROWS.each { |row| print_board_line(row) }
  end

  def []=(choice, symbol)
    squares[choice].mark = symbol
  end

  def open_square_keys(square_keys = ALL_KEYS)
    square_keys.select { |sqr| squares[sqr].empty? }
  end

  def list_open_squares
    join_with_or(open_square_keys)
  end

  def empty?
    open_square_keys.length == 9
  end

  def full?
    open_square_keys.empty?
  end

  def vulnerable_key(line, symbol)
    choice = nil
    open_spaces = open_square_keys(line)
    if open_spaces.count == 1
      if vulnerable_line?(line, symbol)
        choice = open_spaces[0]
      end
    end
    choice
  end

  def winning_mark(first, second)
    WINNING_LINES.each do |line|
      marks_to_check = marks(line)
      return first if marks_to_check.all?(first)
      return second if marks_to_check.all?(second)
    end
    nil
  end

  def reset!
    squares.values.each(&:reset!)
  end

  private

  def marks(nums)
    nums.map { |num| squares[num].to_s }
  end

  def vulnerable_line?(line, symbol)
    marks = marks(line)
    marks.count(symbol) == 2
  end

  def print_board_line(row_number)
    case row_number
    when 1, 13 then puts Square::EMPTY
    when 2, 4, 6, 8, 10, 12 then puts FILLER_ROW
    when 5, 9 then puts DIVIDER_ROW
    else puts build_marked_row(row_number)
    end
  end

  def build_marked_row(row_number)
    grid = FILLER_ROW.chars
    row_marks = lookup_marks(row_number)
    mark_row(grid, row_marks)
    grid.join
  end

  def lookup_marks(row_number)
    case row_number
    when 3
      marks(Square::TOP)
    when 7
      marks(Square::MIDDLE)
    when 11
      marks(Square::BOTTOM)
    end
  end

  def mark_row(grid, nums)
    grid[1] = nums[0]
    grid[5] = nums[1]
    grid[9] = nums[2]
  end
end

class EmptyBoard < Board
  def initialize
    super
    ALL_KEYS.each { |sqr| @squares[sqr] = Square.new }
  end
end

# A board with squares marked 1-9, to illustrate the rules
class RulesBoard < Board
  def initialize
    super
    ALL_KEYS.each { |sqr| @squares[sqr] = Square.new(sqr.to_s) }
  end
end

# Creates a deep copy of the board for the minimax algorithm
class MinimaxBoard < Board
  def initialize(old_board)
    super()
    ALL_KEYS.each do |sqr|
      new_mark = copy_mark(old_board, sqr)
      @squares[sqr] = Square.new(new_mark)
    end
  end

  private

  def copy_mark(board, sqr)
    board.squares[sqr].mark
  end
end

class Square
  TOP = [1, 2, 3]
  MIDDLE = [4, 5, 6]
  BOTTOM = [7, 8, 9]
  CORNERS = [1, 3, 7, 9]
  EMPTY = " "
  CENTER = 5
  attr_accessor :mark

  def initialize(mark = EMPTY)
    @mark = mark
  end

  def empty?
    mark == EMPTY
  end

  def to_s
    mark
  end

  def reset!
    self.mark = EMPTY
  end
end

class Player
  include Output
  attr_reader :symbol, :board, :name
  attr_accessor :choice, :score

  def initialize(board)
    @choice = nil
    @board = board
    @score = 0
  end

  def choose(board, choice, symbol)
    clear_screen
    board[choice] = symbol
    puts "#{name} chooses square #{choice}."
    board.display
  end

  def to_s
    name
  end
end

class Human < Player
  include Input

  SQUARE_INPUT = Board::ALL_KEYS.to_a
  INVALID_SYMBOLS = ["|", "-"]

  def initialize(board)
    @name = prompt_name
    @symbol = prompt_symbol
    super(board)
  end

  def choose
    prompt PROMPTS["yourturn"]
    board.display
    prompt format(PROMPTS["move"], squares: board.list_open_squares)
    input = prompt_square(board)
    choice = input.to_i
    super(board, choice, symbol)
  end

  private

  def prompt_name
    input = nil
    prompt PROMPTS["name_ask"]
    loop do
      input = gets.strip
      break unless input.empty?
      prompt PROMPTS["no_name"]
    end
    input
  end

  def prompt_symbol
    input = nil
    prompt PROMPTS["symbol_ask"]
    loop do
      input = gets.strip
      break if valid_symbol?(input)
      symbol_input_error(input)
    end
    input
  end

  def valid_symbol?(str)
    str.length == 1 && !INVALID_SYMBOLS.include?(str)
  end

  def symbol_input_error(str)
    if str.length != 1
      prompt PROMPTS["invalid_length"]
    else
      prompt PROMPTS["invalid_symbol"]
    end
  end

  def prompt_square(board)
    input = nil
    loop do
      input = gets.strip
      break if valid_choice?(input, board)
      puts square_input_error(input, board)
    end
    input
  end

  def valid_choice?(input, board)
    valid_square?(input) && board.squares[input.to_i].empty?
  end

  def valid_square?(input)
    valid_positive_int?(input) && SQUARE_INPUT.include?(input.to_i)
  end

  def square_input_error(input, board)
    if !valid_square?(input)
      prompt format(PROMPTS["nonum"], squares: board.list_open_squares)
    else
      prompt format(PROMPTS["taken"], squares: board.list_open_squares)
    end
  end
end

class Computer < Player
  attr_reader :opposing_symbol, :difficulty

  def initialize(board, opposing_symbol)
    @symbol = choose_symbol(opposing_symbol)
    @opposing_symbol = opposing_symbol
    super(board)
  end

  private

  def choose_symbol(opponent)
    opponent.upcase == "X" ? "O" : "X"
  end
end

class EasyComputer < Computer
  def initialize(board, opposing_symbol)
    @name = "Randy"
    @difficulty = "easy"
    super(board, opposing_symbol)
  end

  def choose
    choice = board.open_square_keys.sample
    super(board, choice, symbol)
  end
end

class AdvancedComputer < Computer
  def initialize(board, opposing_symbol)
    @name = "Vance"
    @difficulty = "advanced"
    super(board, opposing_symbol)
  end

  def choose
    choice = nil
    if board.squares[Square::CENTER].mark == Square::EMPTY
      choice = Square::CENTER
    end
    if !choice then choice = find_critical_move(symbol) end
    if !choice then choice = find_critical_move(opposing_symbol) end
    if !choice then choice = board.open_square_keys.sample end
    super(board, choice, symbol)
  end

  private

  def find_critical_move(symbol_to_check)
    choice = nil
    Board::WINNING_LINES.each do |line|
      choice = board.vulnerable_key(line, symbol_to_check)
      break if !!choice
    end
    choice
  end
end

class ImpossibleComputer < Computer
  include Output
  MINIMAX_NEG = -100
  MINIMAX_POS = 100

  def initialize(board, opposing_symbol)
    @name = "Max"
    @difficulty = "impossible"
    super(board, opposing_symbol)
  end

  def choose
    prompt PROMPTS["think"]
    choice = choose_strategy
    super(board, choice, symbol)
  end

  private

  # We don't need to do minimax if the board is empty
  # since the optimal move will always be any corner
  def choose_strategy
    if board.empty?
      Square::CORNERS.sample
    else
      minimax(board)[1]
    end
  end

  # rubocop: disable Metrics/AbcSize
  # rubocop: disable Metrics/CyclomaticComplexity
  # rubocop: disable Metrics/PerceivedComplexity
  # rubocop: disable Metrics/MethodLength
  def minimax(
    board, max_turn = true, depth = 0,
    alpha = MINIMAX_NEG, beta = MINIMAX_POS
  )
    best_score = max_turn ? MINIMAX_NEG : MINIMAX_POS
    best_choice = nil
    remaining_keys = board.open_square_keys
    remaining_keys.each do |key|
      new_board = MinimaxBoard.new(board)
      symbol_to_mark = max_turn ? symbol : opposing_symbol
      new_board[key] = symbol_to_mark
      new_score =
        if new_board.full? || new_board.winning_mark(symbol, opposing_symbol)
          end_score(new_board, depth)
        else
          minimax(new_board, !max_turn, (depth + 1), alpha, beta)[0]
        end
      if better_move_found?(max_turn, new_score, best_score)
        best_score = new_score
        best_choice = key
        max_turn ? alpha = best_score : beta = best_score
      end
      break if alpha > beta
    end
    [best_score, best_choice]
  end
  # rubocop: enable Metrics/AbcSize
  # rubocop: enable Metrics/CyclomaticComplexity
  # rubocop: enable Metrics/PerceivedComplexity
  # rubocop: enable Metrics/MethodLength

  def better_move_found?(max_turn, new_score, best_score)
    (max_turn && new_score > best_score) ||
      (!max_turn && new_score < best_score)
  end

  def end_score(board, depth)
    case board.winning_mark(symbol, opposing_symbol)
    when opposing_symbol then (-10 - depth)
    when symbol then (10 - depth)
    else 0
    end
  end
end

class TTTGame
  include Output
  include Input

  DIFFICULTIES = {
    "b" => "beginner",
    "a" => "advanced",
    "i" => "impossible",
    "r" => "random"
  }
  ORDER = { "p" => "player", "c" => "computer", "r" => "random" }

  def initialize
    @board = EmptyBoard.new
    @first_player = nil
    @current_player = nil
    @human = nil
    @computer = nil
    @victory_total = nil
    @winner = nil
  end

  def play
    introduce_game
    loop do
      run_match
      prompt PROMPTS["playagain"]
      play_again = prompt_yes_or_no
      break if no?(play_again)
      reset_game!
    end
    display_end_message
  end

  private

  attr_accessor :board, :winner, :current_player,
                :human, :computer, :victory_total,
                :first_player

  def introduce_game
    clear_screen
    prompt PROMPTS["intro"]
    prompt_rules
    set_players
    set_victory_total
  end

  def prompt_rules
    rules = prompt_yes_or_no
    if yes?(rules) then show_rules end
    clear_screen
  end

  def show_rules
    clear_screen
    prompt PROMPTS["rules_intro"]
    RulesBoard.new.display
    pause
    clear_screen
    prompt PROMPTS["rules_end"]
    pause
  end

  def set_players
    self.human = Human.new(board)
    prompt_computer
    prompt_first_player
  end

  def prompt_computer
    prompt PROMPTS["difficulty"]
    choice = nil
    loop do
      choice = gets.strip.downcase
      break if valid_input?(choice, DIFFICULTIES)
      prompt PROMPTS["invalid_difficulty"]
    end
    if DIFFICULTIES.keys.include?(choice) then choice = DIFFICULTIES[choice] end
    initialize_computer(choice)
  end

  def initialize_computer(choice)
    if choice == "random"
      choice = ["beginner", "advanced", "impossible"].sample
    end
    self.computer = choose_computer_difficulty(choice)
    prompt "Your opponent is #{computer}, the #{computer.difficulty} computer."
  end

  def choose_computer_difficulty(choice)
    case choice
    when "beginner"
      EasyComputer.new(board, human.symbol)
    when "advanced"
      AdvancedComputer.new(board, human.symbol)
    else
      ImpossibleComputer.new(board, human.symbol)
    end
  end

  def prompt_first_player
    choice = nil
    prompt PROMPTS["first_player"]
    loop do
      choice = gets.downcase.strip
      break if valid_input?(choice, ORDER)
      prompt PROMPTS["invalid_first_player"]
    end
    if ORDER.keys.include?(choice) then choice = ORDER[choice] end
    choose_first_player(choice)
  end

  def choose_first_player(choice)
    if choice == "random" then choice = ["player", "computer"].sample end
    self.first_player = choice == "player" ? human : computer
    self.current_player = first_player
    prompt "#{first_player} will go first."
  end

  def set_victory_total
    choice = nil
    prompt PROMPTS["victory"]
    loop do
      choice = gets.strip
      break if valid_positive_int?(choice)
      prompt PROMPTS["invalid_int"]
    end
    self.victory_total = choice.to_i
  end

  def alternate_player
    self.current_player = current_player == human ? computer : human
  end

  def reset_player
    self.current_player = first_player
  end

  def run_match
    loop do
      clear_screen
      run_round
      break if match_over?
      board.reset!
    end
    display_match_winner
  end

  def run_round
    loop do
      current_player.choose
      update_winner
      pause
      break if game_over?
      alternate_player
    end
    finalize_round
  end
  
  def finalize_round
    reset_player
    display_round_results
  end

  def game_over?
    board.full? || winner
  end

  def update_winner
    self.winner = board.winning_mark(human.symbol, computer.symbol)
  end

  def display_match_winner
    if human.score >= victory_total
      prompt PROMPTS["win"]
    else
      prompt PROMPTS["loss"]
    end
  end

  def display_end_message
    prompt PROMPTS["end"]
  end

  def display_round_results
    clear_screen
    board.display
    display_round_winner
    display_scores
    pause
  end

  def display_round_winner
    if winner == human.symbol
      human.score += 1
      prompt PROMPTS["round_win"]
    elsif winner == computer.symbol
      computer.score += 1
      prompt PROMPTS["round_loss"]
    else
      prompt PROMPTS["tie"]
    end
  end

  def display_scores
    newline
    prompt "Current score: #{human}: #{human.score};\
 #{computer}: #{computer.score}."
    newline
  end

  def match_over?
    human.score >= victory_total || computer.score >= victory_total
  end

  def reset_game!
    board.reset!
    human.score = 0
    computer.score = 0
  end
end

game = TTTGame.new
game.play
