require 'yaml'

# Input/output constants

PROMPTS = YAML.load_file('twentyone.yml')
YESNO = { "yes" => ["y"], "no" => ["n"] }
MOVES = {
  "hit" => ["h"],
  "stay" => ["s", "stand"],
  "double" => ["d", "double-down", "double down"]
}

# Game constants

FACE_CARDS = ["Jack", "Queen", "King"]
NUMBER_CARDS = ["2", "3", "4", "5", "6", "7", "8", "9", "10"]

RANKS = ["Ace"] + NUMBER_CARDS + FACE_CARDS
SUITS = ["Spades", "Diamonds", "Hearts", "Clubs"]

BUST_THRESHOLD = 21
DEALER_HIT_THRESHOLD = 16
STARTING_CHIPS = 20

ACE_HIGH = 11
ACE_LOW = 1

# Input/output methods

def clear_screen
  system "clear"
end

def newline
  puts "\n"
end

def prompt(msg)
  puts "=> #{msg}"
end

def pause
  prompt PROMPTS["enter"]
  gets
end

def prompt_yes_or_no
  choice = nil
  loop do
    choice = gets.strip.downcase.gsub(/\./, '')
    break if valid_input?(choice, YESNO)
    prompt PROMPTS["yesno"]
  end
  parse_input(choice, YESNO)
end

# Drawing/showing hands

def draw_card!(game_state, player)
  hand = whose_hand(player)
  game_state[hand] << add_card!(game_state)
end

def add_card!(game_state)
  game_state[:deck].pop
end

def shuffle_deck!(game_state)
  game_state[:deck] = RANKS.product(SUITS).shuffle
end

def draw_initial_hands!(game_state)
  2.times { draw_card!(game_state, "player") }
  2.times { draw_card!(game_state, "dealer") }
  recalculate_value!(game_state, "player")
  recalculate_value!(game_state, "dealer")
end

def whose_hand(player)
  player == "player" ? :player_hand : :dealer_hand
end

def show_hands(game_state)
  show_dealer_hand(game_state)
  show_player_hand(game_state)
  newline
end

def show_dealer_hand(game_state, reveal = false)
  hand = "Dealer's hand: #{hand_to_string(game_state[:dealer_hand], reveal)}"
  if reveal then hand += " (Value: #{game_state[:dealer_value]})" end
  prompt hand
end

def show_player_hand(game_state)
  hand = hand_to_string(game_state[:player_hand])
  prompt "Your hand: #{hand} (Value: #{game_state[:player_value]})"
end

def hand_to_string(hand, reveal = true)
  str = ""
  hand.each do |card|
    str +=
      if face_up?(str, reveal)
        "#{rank(card)} of #{suit(card)}, "
      else
        "unknown, "
      end
  end
  str.delete_suffix(', ') + "."
end

def face_up?(str, reveal)
  str.empty? || reveal
end

# Betting methods

def prompt_winning_total!(game_state)
  total = nil
  loop do
    prompt format(PROMPTS["howmanychips"], chips: STARTING_CHIPS.to_s)
    total = gets.strip
    break if valid_victory_total?(total)
    total_chips_error(total)
  end
  game_state[:victory_total] = total.to_i
end

def valid_victory_total?(total)
  valid_positive_int?(total) && total.to_i > STARTING_CHIPS
end

def total_chips_error(total)
  if !valid_positive_int?(total)
    prompt PROMPTS["invalid_int"]
  else
    prompt format(PROMPTS["toolow"], chips: STARTING_CHIPS.to_s)
  end
end

def show_chips(game_state)
  chips = fix_chip_grammar(game_state)
  prompt "You have #{game_state[:chips]} #{chips}.
    (Playing to #{game_state[:victory_total]})"
end

def show_bet(game_state)
  chips = fix_chip_grammar(game_state)
  prompt "Your bet: #{game_state[:bet]} #{chips}.\n\n"
end

def fix_chip_grammar(game_state)
  game_state[:chips] == 1 ? "chip" : "chips"
end

def make_bet!(game_state)
  bet = nil
  loop do
    prompt PROMPTS["bet"]
    bet = gets.strip
    break if valid_bet?(bet, game_state)
    bet_error(bet)
  end
  game_state[:bet] = bet.to_i
end

def valid_bet?(input, game_state)
  valid_positive_int?(input) && possible_bet?(input, game_state)
end

def valid_positive_int?(input)
  input.to_i.to_s == input && input.to_i > 0
end

def possible_bet?(bet, game_state)
  bet.to_i <= game_state[:chips]
end

def bet_error(bet)
  if !valid_positive_int?(bet)
    prompt PROMPTS["invalid_int"]
  else
    prompt PROMPTS["toohigh"]
  end
end

def resolve_bet!(winner, game_state)
  case winner
  when "Player" then game_state[:chips] += game_state[:bet]
  when "Dealer" then game_state[:chips] -= game_state[:bet]
  end
end

# Helper methods for hand calculation

def hand_value(hand)
  sum = 0
  ranks(hand).each do |value|
    sum +=
      if face_card?(value) then 10
      elsif number_card?(value) then value.to_i
      elsif sum + ACE_HIGH > BUST_THRESHOLD then ACE_LOW
      else ACE_HIGH
      end
  end
  sum
end

# We move aces to the end of the array to calculate their value last.
# This simplifies the logic for calculating the aces' score.
def ranks(cards)
  ranks = cards.map { |card| rank(card) }
  non_aces, aces = ranks.partition { |name| name != "Ace" }
  non_aces + aces
end

def rank(card)
  card[0]
end

def suit(card)
  card[1]
end

def face_card?(value)
  FACE_CARDS.include?(value)
end

def number_card?(value)
  NUMBER_CARDS.include?(value)
end

def recalculate_value!(game_state, player)
  hand = whose_hand(player)
  value = whose_value(player)
  game_state[value] = hand_value(game_state[hand])
end

def whose_value(player)
  player == "player" ? :player_value : :dealer_value
end

# Game loop

def introduce_game
  clear_screen
  prompt PROMPTS["intro"]
  rules = prompt_yes_or_no
  if rules == "yes" then print_rules end
end

def print_rules
  print_intro_rules
  print_gameplay_rules
  print_winning_rules
end

def print_intro_rules
  clear_screen
  prompt PROMPTS["rules_intro"]
  prompt format(PROMPTS["rules_goal"], score: BUST_THRESHOLD)
  prompt PROMPTS["rules_score"]
  prompt format(PROMPTS["rules_aces"], score: BUST_THRESHOLD)
  prompt PROMPTS["rules_aces2"]
  pause
end

def print_gameplay_rules
  clear_screen
  prompt format(PROMPTS["rules_chips"], chips: STARTING_CHIPS)
  prompt PROMPTS["rules_game"]
  prompt format(PROMPTS["rules_moves"], score: BUST_THRESHOLD)
  prompt PROMPTS["rules_moves2"]
  pause
end

def print_winning_rules
  clear_screen
  prompt format(PROMPTS["rules_winning"], score: BUST_THRESHOLD)
  prompt PROMPTS["rules_winning2"]
  pause
end

def reset_game!(game_state)
  game_state[:player_hand] = []
  game_state[:dealer_hand] = []
  game_state[:player_value] = 0
  game_state[:dealer_value] = 0

  shuffle_deck!(game_state)
end

def reset_chips!(game_state)
  game_state[:chips] = STARTING_CHIPS
end

def play_game(game_state)
  loop do
    reset_chips!(game_state)
    run_game(game_state)
    prompt PROMPTS["playagain"]
    break if prompt_yes_or_no == "no"
  end
end

def run_game(game_state)
  loop do
    prep_round(game_state)
    run_round(game_state)
    clear_screen
    resolve_round(game_state)
    if game_state[:chips] <= 0
      prompt PROMPTS["nochips"]
      break
    elsif game_state[:chips] >= game_state[:victory_total]
      prompt format(PROMPTS["won"], chips: game_state[:chips])
      break
    end
  end
end

def prep_round(game_state)
  clear_screen
  reset_game!(game_state)
  draw_initial_hands!(game_state)
  prompt PROMPTS["newround"]
  show_chips(game_state)
  make_bet!(game_state)
  clear_screen
end

def run_round(game_state)
  loop do
    prompt PROMPTS["hands"]
    show_hands(game_state)
    break if first_turn_blackjack?(game_state)
    player_turn!(game_state)
    break if player_done?(game_state)
    dealer_turn!(game_state)
    break if dealer_done?(game_state)
    clear_screen
  end
end

def resolve_round(game_state)
  show_dealer_hand(game_state, true)
  show_player_hand(game_state)
  newline
  result = determine_result(game_state)
  print_result(result)
  pause
  clear_screen
  resolve_bet!(result[0], game_state)
end

# Gameplay methods

def player_turn!(game_state)
  show_chips(game_state)
  show_bet(game_state)
  game_state["move"] = parse_player_move(game_state)
  case game_state["move"]
  when "stay" then prompt PROMPTS["stay"]
  when "hit" then hit!(game_state)
  else double_down!(game_state)
  end
  pause
end

def parse_player_move(game_state)
  choice = nil
  loop do
    if can_double?(game_state)
      prompt PROMPTS["moves_double"]
    else
      prompt PROMPTS["moves"]
    end
    choice = gets.strip.downcase
    break if valid_choice?(choice, game_state)
    prompt move_error(choice, MOVES)
  end
  parse_input(choice, MOVES)
end

def valid_choice?(choice, game_state)
  if parse_input(choice, MOVES) == "double" && !can_double?(game_state)
    return false
  end
  valid_input?(choice, MOVES)
end

def valid_input?(choice, commands)
  commands.keys.include?(choice) || valid_full_input?(choice, commands)
end

def valid_full_input?(choice, commands)
  commands.values.each do |aliases|
    return true if aliases.include?(choice)
  end
  false
end

def parse_input(choice, commands)
  if commands.keys.include?(choice)
    choice
  else
    commands.each do |key, aliases|
      return key if aliases.include?(choice)
    end
  end
end

def move_error(choice, commands)
  if !valid_input?(choice, commands)
    prompt PROMPTS["invalid"]
  else
    prompt PROMPTS["no_double"]
  end
end

def can_double?(game_state)
  first_turn?(game_state) && enough_chips_to_double?(game_state)
end

def first_turn?(game_state)
  game_state[:player_hand].size == 2
end

def enough_chips_to_double?(game_state)
  game_state[:bet] * 2 <= game_state[:chips]
end

def hit!(game_state)
  draw_card!(game_state, "player")
  recalculate_value!(game_state, "player")
  prompt PROMPTS["hit"]
  show_player_hand(game_state)
end

def double_down!(game_state)
  game_state[:bet] *= 2
  draw_card!(game_state, "player")
  recalculate_value!(game_state, "player")
  prompt format(PROMPTS["double"], bet: game_state[:bet])
  show_player_hand(game_state)
end

def dealer_turn!(game_state)
  if game_state[:dealer_value] > DEALER_HIT_THRESHOLD
    prompt PROMPTS["dealer_stay"]
  else
    draw_card!(game_state, "dealer")
    recalculate_value!(game_state, "dealer")
    prompt PROMPTS["dealer_hit"]
  end
  pause
end

# Checking game status and ending round

def first_turn_blackjack?(game_state)
  perfect?(game_state, "player") || perfect?(game_state, "dealer")
end

def player_done?(game_state)
  busted?(game_state, "player") ||
    perfect?(game_state, "player") ||
    done_drawing?(game_state["move"])
end

def done_drawing?(move)
  move == "stay" || move == "double"
end

def dealer_done?(game_state)
  busted?(game_state, "dealer") || perfect?(game_state, "dealer")
end

def player_blackjack?(game_state)
  perfect?(game_state, "player") && !perfect?(game_state, "dealer")
end

def print_result(result)
  prompt result[1] + "\n\n"
end

def busted?(game_state, player)
  score = whose_value(player)
  game_state[score] > BUST_THRESHOLD
end

def perfect?(game_state, player)
  value = whose_value(player)
  game_state[value] == BUST_THRESHOLD
end

# Returns an array of the winner and the message to print.
def determine_result(game_state)
  if busted?(game_state, "player")
    ["Dealer", "*** You busted! ***"]
  elsif player_blackjack?(game_state)
    ["Player", "*** Blackjack! You scored 21! ***"]
  elsif busted?(game_state, "dealer")
    ["Player", "*** Dealer busted! ***"]
  elsif game_state[:player_value] > game_state[:dealer_value]
    ["Player", "*** You won! ***"]
  elsif game_state[:dealer_value] > game_state[:player_value]
    ["Dealer", "*** You lost. ***"]
  else
    [nil, "*** It's a tie! ***"]
  end
end

game_state = {
  player_hand: [],
  dealer_hand: [],
  player_value: 0,
  dealer_value: 0,
  chips: STARTING_CHIPS,
  victory_total: nil,
  bet: nil,
  deck: []
}

introduce_game
clear_screen
prompt_winning_total!(game_state)
play_game(game_state)
prompt PROMPTS["end"]
