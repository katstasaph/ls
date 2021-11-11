require 'yaml'

# Board constants

TOP_LEFT = 1
TOP_MIDDLE = 2
TOP_RIGHT = 3
MIDDLE_LEFT = 4
MIDDLE = 5
MIDDLE_RIGHT = 6
BOTTOM_LEFT = 7
BOTTOM_MIDDLE = 8
BOTTOM_RIGHT = 9

DIVIDER_ROW = "-----------"
FILLER_ROW = "   |   |   "

# Input/output constants

PROMPTS = YAML.load_file('tictactoe.yml')

PLAYER_SYMBOL = "X"
COMP_SYMBOL = "O"
NO_SYMBOL = " "

YESNO = { "y" => "yes", "n" => "no" }
DIFFICULTIES = { "b" => "beginner", "a" => "advanced", "i" => "impossible" }
FIRST_PLAYERS = { "p" => "player", "c" => "computer", "r" => "random" }
PLAYERS = ["player", "computer"]
SQUARE_INPUT = (1..9).to_a

# Game constants

WINNING_LINES = [
  [1, 2, 3], [4, 5, 6], [7, 8, 9], [1, 4, 7],
  [2, 5, 8], [3, 6, 9], [1, 5, 9], [3, 5, 7]
]

MINIMAX_NEG = -100
MINIMAX_POS = 100

# General input/output methods

def prompt(msg)
  puts "=> #{msg}"
end

def prompt_anykey
  prompt PROMPTS["anykey"]
  gets
end

def clear_screen
  system "clear"
end

def valid_input?(input, valid_inputs)
  valid_inputs.keys.include?(input) || valid_inputs.values.include?(input)
end

def prompt_yes_or_no
  choice = nil
  loop do
    choice = gets.strip.downcase.gsub(/\./, '')
    break if valid_input?(choice, YESNO)
    prompt PROMPTS["yesno"]
  end
  if YESNO.keys.include?(choice) then choice = YESNO[choice] end
  choice
end

# Building, previewing, and clearing the board

def print_board(board_state)
  (1..13).each { |row| print_board_line(row, board_state) }
end

def print_board_line(row_number, board_state)
  case row_number
  when 1, 13 then puts NO_SYMBOL
  when 2, 4, 6, 8, 10, 12 then puts FILLER_ROW
  when 5, 9 then puts DIVIDER_ROW
  else puts build_marked_row(row_number, board_state)
  end
end

def build_marked_row(row_number, board_state)
  grid = FILLER_ROW.chars
  squares = []
  case row_number
  when 3
    squares = get_marks([1, 2, 3], board_state)
  when 7
    squares = get_marks([4, 5, 6], board_state)
  when 11
    squares = get_marks([7, 8, 9], board_state)
  end
  mark_row(grid, squares)
  grid.join
end

def get_marks(squares, board_state)
  squares.map { |square| board_state[square] }
end

def mark_row(grid, squares)
  grid[1] = squares[0]
  grid[5] = squares[1]
  grid[9] = squares[2]
end

def clear_board!(board_state)
  board_state.transform_values! { NO_SYMBOL }
end

def initialize_preview_board!(board_state)
  SQUARE_INPUT.each { |square| board_state[square] = square.to_s }
end

def update_board(board_state)
  clear_board!(board_state)
  print_board(board_state)
end

# Initializing settings

def initialize_settings!(settings)
  initialize_difficulty!(settings)
  initialize_rounds!(settings)
  initialize_scores!(settings)
  initialize_first_player!(settings)
end

def switch_player(player)
  player == "computer" ? "player" : "computer"
end

def initialize_difficulty!(settings)
  choice = nil
  prompt PROMPTS["difficulty"]
  loop do
    choice = gets.downcase.strip
    break if valid_input?(choice, DIFFICULTIES)
    prompt PROMPTS["invalid_difficulty"]
  end
  if DIFFICULTIES.keys.include?(choice) then choice = DIFFICULTIES[choice] end
  settings[:difficulty] = choice
end

def initialize_rounds!(settings)
  choice = nil
  prompt PROMPTS["victory"]
  loop do
    choice = gets.strip
    break if valid_positive_int?(choice)
    prompt PROMPTS["invalid_int"]
  end
  settings[:rounds] = choice.to_i
  settings[:current_round] = 0
end

def initialize_scores!(settings)
  settings[:you_score] = 0
  settings[:comp_score] = 0
end

def valid_positive_int?(input)
  input.to_i.to_s == input && input.to_i > 0
end

def update_score!(scores, winner)
  winner == "Player" ? scores[:you_score] += 1 : scores[:comp_score] += 1
end

def initialize_first_player!(settings)
  choice = nil
  prompt PROMPTS["first_player"]
  loop do
    choice = gets.downcase.strip
    break if valid_input?(choice, FIRST_PLAYERS)
    prompt PROMPTS["invalid_first_player"]
  end
  if FIRST_PLAYERS.keys.include?(choice) then choice = FIRST_PLAYERS[choice] end
  settings[:first_player] = choice
end

def assign_first_player(settings)
  settings[:first_player] == "random" ? PLAYERS.sample : settings[:first_player]
end

# Game loop

def play_game(board_state, game_state)
  initialize_settings!(game_state)
  clear_screen
  run_game!(board_state, game_state)
end

def introduce_game!(board_state)
  clear_screen
  initialize_preview_board!(board_state)
  prompt PROMPTS["intro"]
  rules = prompt_yes_or_no
  if rules == "yes" then show_rules(board_state) end
end

def show_rules(board_state)
  clear_screen
  prompt PROMPTS["rules_intro"]
  print_board(board_state)
  prompt_anykey
  clear_screen
  prompt PROMPTS["rules_end"]
  prompt_anykey
end

def run_game!(board_state, game_state)
  current_player = assign_first_player(game_state)
  run_round!(board_state, game_state, current_player)
  prompt_anykey
end

def run_round!(board_state, game_state, current_player)
  loop do
    clear_board!(board_state)
    introduce_round!(game_state)
    loop do
      do_turn!(current_player, board_state, game_state)
      break if round_over?(board_state)
      current_player = switch_player(current_player)
    end
    do_round_end(board_state, game_state)
    break unless new_round?(game_state)
    current_player = assign_first_player(game_state)
    print_current_score(game_state)
  end
end

def introduce_round!(game_state)
  game_state[:current_round] += 1
  prompt format(PROMPTS["current_round"], round: game_state[:current_round])
end

def do_turn!(player, board_state, game_state)
  move = nil
  if player == "player"
    move = do_player_turn!(board_state)
    p move
  else
    if game_state[:difficulty] == "impossible" then prompt PROMPTS["think"] end
    move = do_computer_turn!(board_state, game_state)
  end
  end_turn(board_state, player, move)
  clear_screen
end

def list_open_squares(board_state)
  joinor(available_squares(board_state))
end

def joinor(arr)
  newarr = arr.map { |num| (num.to_s) + "," }
  if newarr.length > 1
    if newarr.length == 2 then newarr[-2].delete_suffix(",") end
    newarr[-2] += " or"
  end
  newarr[-1] = newarr[-1].delete_suffix(",")
  newarr.join(" ")
end

# Player's turn

def do_player_turn!(board_state)
  choice = nil
  print_board(board_state)
  prompt PROMPTS["yourturn"]
  prompt format(PROMPTS["move"], squares: list_open_squares(board_state))
  loop do
    choice = gets.strip.to_i
    break if valid_choice?(choice, board_state)
    puts input_error(choice, board_state)
  end
  board_state[choice] = PLAYER_SYMBOL
  choice
end

def valid_choice?(input, board_state)
  !(invalid_square?(input) || square_taken?(input, board_state))
end

def invalid_square?(input)
  !SQUARE_INPUT.include?(input)
end

def square_taken?(square, board_state)
  board_state[square] != NO_SYMBOL
end

def available_squares(board_state)
  board_state.select { |square| board_state[square] == NO_SYMBOL }.keys
end

def input_error(input, board_state)
  if invalid_square?(input)
    prompt format(PROMPTS["nonum"], squares: list_open_squares(board_state))
  else
    prompt format(PROMPTS["taken"], squares: list_open_squares(board_state))
  end
end

def end_turn(board_state, player, move)
  clear_screen
  if player == "player"
    prompt format(PROMPTS["you_move"], movenum: move)
  else
    prompt format(PROMPTS["comp_move"], movenum: move)
  end
  print_board(board_state)
  prompt_anykey
end

# Computer's turn

def do_computer_turn!(board_state, game_state)
  print_board(board_state)
  square =
    case game_state[:difficulty]
    when "beginner" then easy_strategy(board_state)
    when "advanced" then advanced_strategy(board_state)
    else minimax(board_state)[1]
    end
  board_state[square] = COMP_SYMBOL
  square
end

def easy_strategy(board_state)
  available_squares(board_state).sample
end

# Methods for Advanced: basic offense and defense

def advanced_strategy(board_state)
  square = nil
  if board_state[5] == NO_SYMBOL then square = 5 end
  if !square then square = offense_strategy(board_state) end
  if !square then square = defense_strategy(board_state) end
  if !square then square = available_squares(board_state).sample end
  square
end

def offense_strategy(board_state)
  square = nil
  WINNING_LINES.each do |line|
    squares_to_check = board_state.select { |key, _| line.include?(key) }
    square = detect_vulnerable_square(squares_to_check, COMP_SYMBOL)
    break if !!square
  end
  square
end

def defense_strategy(board_state)
  square = nil
  WINNING_LINES.each do |line|
    squares_to_check = board_state.select { |key, _| line.include?(key) }
    square = detect_vulnerable_square(squares_to_check, PLAYER_SYMBOL)
    break if !!square
  end
  square
end

def detect_vulnerable_square(line, symbol)
  square = nil
  if line.values.count(symbol) == 2
    square = line.key(NO_SYMBOL)
  end
  square
end

# Methods for Impossible strategy: minimax w/ alpha-beta pruning

# rubocop: disable Metrics/AbcSize
# rubocop: disable Metrics/CyclomaticComplexity
# rubocop: disable Metrics/PerceivedComplexity
# rubocop: disable Metrics/MethodLength
def minimax(
  possible_state, max_turn = true, depth = 0,
  alpha = MINIMAX_NEG, beta = MINIMAX_POS
)
  best_score = max_turn ? MINIMAX_NEG : MINIMAX_POS
  best_move = nil
  available_squares(possible_state).each do |square|
    new_state = possible_state.dup
    new_state[square] = max_turn ? COMP_SYMBOL : PLAYER_SYMBOL
    new_score =
      if round_over?(new_state)
        end_score(new_state, depth)
      else
        minimax(new_state, !max_turn, (depth + 1), alpha, beta)[0]
      end
    if max_turn && new_score > best_score
      best_score = new_score
      best_move = square
      alpha = best_score
    elsif !max_turn && new_score < best_score
      best_score = new_score
      best_move = square
      beta = best_score
    end
    break if alpha > beta
  end
  [best_score, best_move]
end
# rubocop: enable Metrics/AbcSize
# rubocop: enable Metrics/CyclomaticComplexity
# rubocop: enable Metrics/PerceivedComplexity
# rubocop: enable Metrics/MethodLength

def end_score(board, depth)
  case detect_winner(board)
  when "Player" then (-10 - depth)
  when "Computer" then (10 - depth)
  else 0
  end
end

# Assessing board state

def round_over?(board_state)
  someone_won?(board_state) || board_full?(board_state)
end

def someone_won?(board_state)
  winner = detect_winner(board_state)
  !!winner ? winner : nil
end

def detect_winner(board_state)
  WINNING_LINES.each do |line|
    squares_to_check = board_state.select { |key, _| line.include?(key) }
    if player_wins_line?(squares_to_check) then return "Player" end
    if computer_wins_line?(squares_to_check) then return "Computer" end
  end
  false
end

def player_wins_line?(line)
  winning_line?(line, PLAYER_SYMBOL)
end

def computer_wins_line?(line)
  winning_line?(line, COMP_SYMBOL)
end

def winning_line?(squares, symbol)
  squares.all? { |_, value| value == symbol }
end

def board_full?(board_state)
  board_state.values.none?(NO_SYMBOL)
end

# Transitions

def print_current_score(game_state)
  prompt format(PROMPTS["you_score"], score: game_state[:you_score])
  prompt format(PROMPTS["comp_score"], score: game_state[:comp_score])
  prompt_anykey
end

def do_round_end(board_state, game_state)
  if someone_won?(board_state)
    winner = detect_winner(board_state)
    print_winning_message(winner)
    update_score!(game_state, winner)
  else
    prompt PROMPTS["tie"]
  end
end

def print_winning_message(winner)
  prompt winner == "Player" ? PROMPTS["round_win"] : PROMPTS["round_loss"]
end

def new_round?(state)
  state[:you_score] < state[:rounds] && state[:comp_score] < state[:rounds]
end

def print_match_winner(state)
  prompt state[:you_score] == state[:rounds] ? PROMPTS["win"] : PROMPTS["loss"]
  prompt PROMPTS["playagain"]
end

# Game loop

game_state = {
  first_player: nil,
  difficulty: nil,
  rounds: nil,
  you_score: nil,
  comp_score: nil,
  current_round: nil
}

board_state = {}

introduce_game!(board_state)
loop do
  play_game(board_state, game_state)
  print_match_winner(game_state)
  break if prompt_yes_or_no == "no"
end
prompt PROMPTS["end"]
