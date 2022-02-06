require 'yaml'
PROMPTS = YAML.load_file('twentyone.yml')

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

  def parse_input(input, valid_inputs)
    valid_inputs.key?(input) ? valid_inputs[input] : input
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

# Move methods for players.
module Movable
  def move(choice)
    case choice
    when "hit"
      hit
    when "stand"
      stand
    when "double"
      double
    end
  end

  def hit
    hand << deck.remove(1)
  end

  def stand
    self.taking_turns = false
  end

  def double
    double_bet
    self.taking_turns = false
    hit
  end
end

module Strategy
  # The strategy is taken from the first chart here:
  # www.casinoguardian.co.uk/blackjack/
  # blackjack-illustrious-18/
  #
  # (Disregards double/split)

  # Data structure:
  # dealer value => [player card to stand on]
  # A "hard" hand has no aces; its value is fixed
  # Since soft hands have aces, hitting is safer
  STRATEGY = {
    hard: {
      12 => ["4", "5", "6"],
      13 => ["2", "3", "4", "5", "6"],
      14 => ["2", "3", "4", "5", "6"],
      15 => ["2", "3", "4", "5", "6"],
      16 => ["2", "3", "4", "5", "6"]
    },
    soft: {
      18 => ["2", "7", "8"],
      19 => ["2", "3", "4", "5", "7", "8", "9", "Ace"]
    }
  }

  def strategic_move(other)
    hand_type = hand.hard? ? :hard : :soft
    hand_value = hand.value
    return "hit" if hand_type == :soft && hand_value < 18
    other = other.rank
    lookup_strat(hand_type, hand_value, other)
  end

  def lookup_strat(hand_type, hand_value, other)
    rule = STRATEGY[hand_type]
    strat_applies?(rule, hand_value, other) ? "stand" : nil
  end

  def strat_applies?(rule, hand_value, other)
    rule.key?(hand_value) && rule[hand_value].include?(other)
  end
end

module CardCounting
  # Strategy is a simplified version of the Illustrious 18:
  #
  # www.blackjackinfo.com/community/threads/
  # illustrious-18-for-a-newcomer.1874/
  #
  # This strategy is only for hard hands, not soft
  # It again disregards double, split, etc.

  # Data structure:
  # [dealer value, human value] => count to stand at/above
  COUNT_STRATEGY = {
    [16, 10] => 0,
    [16, 9] => 5,
    [15, 10] => 4,
    [13, 2] => -1,
    [13, 3] => -2,
    [12, 2] => 3,
    [12, 3] => 2,
    [12, 4] => 0,
    [12, 5] => -2,
    [12, 6] => -1
  }

  def counting_move(count, other)
    return nil unless hand.hard?
    other = other.disregard_face.to_i
    lookup_count(count, hand.value, other)
  end

  def lookup_count(count, hand_value, other)
    both_values = [hand_value, other]
    counting_applies?(both_values, count) ? "stand" : nil
  end

  def counting_applies?(both, count)
    hand_present?(both) && threshold_met?(both, count)
  end

  def hand_present?(both)
    COUNT_STRATEGY.key?(both)
  end

  def threshold_met?(both, count)
    count >= COUNT_STRATEGY[both]
  end
end

class CardContainer
  attr_accessor :cards

  def initialize
    @cards = []
  end

  def <<(new_cards)
    new_cards.each { |card| cards << card }
  end

  def size
    cards.length
  end

  def remove(number = nil)
    if !number
      number = cards.size
    end
    cards.pop(number)
  end

  def +(other)
    cards + other.cards
  end
end

class Deck < CardContainer
  def initialize
    @cards = build_deck
  end

  def shuffle
    cards.shuffle!
  end

  private

  def build_deck
    types = all_cards
    init_cards(types)
  end

  def all_cards
    number_cards = Card::NUMBER_CARDS.product(Card::SUITS).shuffle
    face_cards = Card::FACE_CARDS.product(Card::SUITS).shuffle
    aces = ["Ace"].product(Card::SUITS).shuffle
    [number_cards, face_cards, aces]
  end

  # rubocop: disable Metrics/AbcSize
  def init_cards(types)
    deck = []
    types[0].each { |card| deck << NumberCard.new(card[0], card[1]) }
    types[1].each { |card| deck << FaceCard.new(card[0], card[1]) }
    types[2].each { |card| deck << Ace.new(card[0], card[1]) }
    deck.shuffle
  end
  # rubocop: enable Metrics/AbcSize
end

class Hand < CardContainer
  MAX_VALUE = 21

  attr_accessor :face_down, :value

  def initialize(face_down = false)
    @face_down = face_down
    @value = 0
    super()
  end

  def <<(new_cards)
    super(new_cards)
    self.value = calculate_value
  end

  def visible_card
    cards[0]
  end

  def to_s
    str = "#{visible_card}, "
    cards.drop(1).each do |card|
      str += face_down ? "unknown, " : "#{card}, "
    end
    str.delete_suffix(", ")
  end

  def hard?
    cards.none? { |card| card.class == Ace }
  end

  private

  def calculate_value
    cards_to_add = move_aces(cards)
    cards_to_add.inject(0) { |sum, card| sum + card.value(sum) }
  end

  # As before we calculate the aces' value last.
  def move_aces(cards)
    non_aces, aces = cards.partition { |card| card.class != Ace }
    non_aces + aces
  end
end

# Cards have a "score" used for card counting:
# Face cards and aces worth -1; ranks 2-6 worth 1; others 0
class Card
  FACE_CARDS = ["Jack", "Queen", "King"]
  NUMBER_CARDS = ["2", "3", "4", "5", "6", "7", "8", "9", "10"]
  SUITS = ["Spades", "Diamonds", "Hearts", "Clubs"]

  HILO_HIGH = 1
  HILO_LOW = -1

  attr_reader :suit, :rank, :value, :hilo_score

  def initialize(rank, suit)
    @rank = rank
    @suit = suit
    @value = value
    @hilo_score = set_hilo_score
  end

  def to_s
    "#{rank} of #{suit}"
  end

  def disregard_face
    if FACE_CARDS.include?(rank)
      "10"
    else
      rank
    end
  end
end

class NumberCard < Card
  def value(*)
    rank.to_i
  end

  private

  def set_hilo_score
    value > 6 ? Card::HILO_HIGH : 0
  end
end

class FaceCard < Card
  def value(*)
    10
  end

  private

  def set_hilo_score
    Card::HILO_LOW
  end
end

class Ace < Card
  LOW = 1
  HIGH = 11

  def value(sum = 0)
    sum + HIGH > Hand::MAX_VALUE ? LOW : HIGH
  end

  private

  def set_hilo_score
    Card::HILO_LOW
  end
end

class Player
  include Output
  include Movable

  attr_reader :name
  attr_accessor :hand, :deck, :taking_turns

  def initialize(deck)
    @deck = deck
    @taking_turns = true
  end

  def draw_hand
    hand << deck.remove(2)
  end

  def new_hand
    deck << (hand.remove)
    deck.shuffle
    self.taking_turns = true
  end

  def show_hand
    str = "#{name}'s hand: #{hand}"
    unless hand.face_down then str += (" (Value: #{hand.value})") end
    prompt str
  end

  def choose_move(choice)
    move(choice)
    prompt "#{name} chooses to #{choice}."
    show_hand
    newline
    pause
  end

  def blackjack?
    hand.value == Hand::MAX_VALUE
  end

  def busted?
    hand.value > Hand::MAX_VALUE
  end

  def done?
    busted? || blackjack?
  end

  def >(other_player)
    hand.value > other_player.hand.value
  end

  def visible_card
    hand.visible_card
  end

  def reset!
    new_hand
  end
end

class Human < Player
  include Input
  include Output

  MOVES = {
    "h" => "hit",
    "s" => "stand",
    "stay" => "stand",
    "d" => "double",
    "double down" => "double"
  }

  attr_accessor :win_total, :bet, :chips

  def initialize(deck, chips)
    @hand = Hand.new
    @name = prompt_name
    @chips = chips
    @bet = nil
    super(deck)
  end

  def show_chips
    chip_str = fix_chip_grammar
    prompt "You have #{chips} #{chip_str}."
  end

  def take_turn(*)
    choose_move
  end

  def done?
    super || !taking_turns
  end

  def resolve_bet(winner)
    if winner == :human
      self.chips += bet
    elsif winner == :dealer
      self.chips -= bet
    end
  end

  def reset!(new_chips)
    self.chips = new_chips
    super()
  end

  private

  def choose_move
    choice = prompt_move
    super(choice)
  end

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

  def prompt_move
    choice = nil
    loop do
      show_move_prompt
      choice = gets.strip.downcase
      break if valid_choice?(choice)
      prompt move_error(choice, MOVES)
    end
    parse_input(choice, MOVES)
  end

  def show_move_prompt
    if can_double?
      prompt PROMPTS["moves_double"]
    else
      prompt PROMPTS["moves"]
    end
    show_bet_info
  end

  def show_bet_info
    show_chips
    prompt "(Current bet: #{bet})"
  end

  def fix_chip_grammar
    chips == 1 ? "chip" : "chips"
  end

  def valid_choice?(choice)
    return false if invalid_double?(choice)
    valid_input?(choice, MOVES)
  end

  def move_error(choice, commands)
    if !valid_input?(choice, commands)
      prompt PROMPTS["invalid"]
    else
      prompt PROMPTS["no_double"]
    end
  end

  def invalid_double?(choice)
    choice == "double" && !can_double?
  end

  def can_double?
    hand.size == 2 && enough_chips_to_double?
  end

  def enough_chips_to_double?
    bet * 2 <= chips
  end

  def double_bet
    self.bet *= 2
    prompt format(PROMPTS["double"], bet: bet)
  end
end

class Dealer < Player
  STAND_ABOVE = 16

  def initialize(deck)
    @name = "Dealer"
    @hand = Hand.new(true)
    super(deck)
  end

  def take_turn(other_card)
    unless taking_turns
      prompt "#{name} stands."
      newline
      return
    end
    @other_card = other_card
    choose_move
  end

  def reveal
    hand.face_down = false
  end

  def new_hand
    super
    hand.face_down = true
  end

  private

  attr_reader :other_card

  def choose_move(choice = nil)
    if !choice
      choice = hand.value > STAND_ABOVE ? "stand" : "hit"
    end
    super(choice)
  end
end

# This dealer uses an improved strategy to select cards.
class SmartDealer < Dealer
  include Strategy

  private

  def choose_move
    choice = strategic_move(other_card)
    choice ? super(choice) : super
  end
end

# This dealer applies card counting AI first
# Then falls back on previous strategy if no rules apply
class CountingDealer < Dealer
  include Strategy
  include CardCounting

  attr_accessor :count, :seen_cards

  def initialize(deck)
    @count = 0
    @seen_cards = []
    super(deck)
  end

  def new_hand
    super
    self.count = 0
    self.seen_cards = []
  end

  private

  def choose_move
    update_count
    choice = counting_move(count, other_card)
    if !choice
      choice = strategic_move(other_card)
    end
    super(choice)
  end

  def update_count
    hand.cards.each { |card| do_count(card) }
    do_count(other_card)
  end

  def do_count(card)
    unless seen_cards.include?(card)
      seen_cards << card
      self.count += card.hilo_score
    end
  end
end

class TwentyOneGame
  include Input
  include Output

  START_CHIPS = 20

  DIFFICULTIES = {
    "e" => "easy",
    "i" => "intermediate",
    "h" => "hard"
  }

  def initialize
    @deck = Deck.new
    @human = nil
    @dealer = nil
    @winner = nil
    @win_total = nil
  end

  def play
    prep_game
    loop do
      run_game
      prompt PROMPTS["playagain"]
      play_again = prompt_yes_or_no
      break if no?(play_again)
      reset_game!
    end
    prompt PROMPTS["end"]
  end

  private

  attr_accessor :deck, :human, :dealer, :win_total, :winner

  def run_game
    loop do
      run_round
      if game_over?
        resolve_game
        break
      end
    end
  end

  def run_round
    prep_round
    play_round
    resolve_round
  end

  def prep_game
    clear_screen
    prompt PROMPTS["intro"]
    rules = prompt_yes_or_no
    if yes?(rules) then print_rules end
    prep_settings
  end

  def prep_settings
    clear_screen
    set_players
    prompt_win_total
  end

  def print_rules
    print_intro_rules
    print_gameplay_rules
    print_winning_rules
    print_difficulty_rules
  end

  def print_intro_rules
    clear_screen
    prompt PROMPTS["rules_intro"]
    prompt format(PROMPTS["rules_goal"], score: Hand::MAX_VALUE)
    prompt PROMPTS["rules_score"]
    prompt format(PROMPTS["rules_aces"], score: Hand::MAX_VALUE)
    prompt PROMPTS["rules_aces2"]
    pause
  end

  def print_gameplay_rules
    clear_screen
    prompt format(PROMPTS["rules_chips"], chips: START_CHIPS)
    prompt PROMPTS["rules_game"]
    prompt format(PROMPTS["rules_moves"], score: Hand::MAX_VALUE)
    prompt PROMPTS["rules_moves2"]
    pause
  end

  def print_winning_rules
    clear_screen
    prompt format(PROMPTS["rules_winning"], score: Hand::MAX_VALUE)
    prompt PROMPTS["rules_winning2"]
    pause
  end

  def print_difficulty_rules
    clear_screen
    prompt PROMPTS["rules_difficulty"]
    pause
  end

  def set_players
    self.human = Human.new(deck, START_CHIPS)
    self.dealer = prompt_dealer_type
  end

  def prompt_dealer_type
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
    case choice
    when "easy"
      Dealer.new(deck)
    when "intermediate"
      SmartDealer.new(deck)
    else
      CountingDealer.new(deck)
    end
  end

  def prompt_win_total
    total = nil
    loop do
      prompt format(PROMPTS["chips"], chips: START_CHIPS.to_s)
      total = gets.strip
      break if valid_victory_total?(total)
      total_chips_error(total)
    end
    apply_win_total(total)
  end

  def valid_victory_total?(total)
    valid_positive_int?(total) && total.to_i > START_CHIPS
  end

  def total_chips_error(total)
    if !valid_positive_int?(total)
      prompt PROMPTS["invalid_int"]
    else
      prompt format(PROMPTS["toolow"], chips: START_CHIPS.to_s)
    end
  end

  def apply_win_total(total)
    self.win_total = total.to_i
    human.win_total = win_total
  end

  def prep_round
    clear_screen
    prompt PROMPTS["newround"]
    human.show_chips
    prompt "(Playing to #{win_total})"
    newline
    prompt_bet
  end

  def prompt_bet
    input = nil
    loop do
      prompt PROMPTS["bet"]
      input = gets.strip
      break if valid_bet?(input)
      bet_error(input)
    end
    human.bet = input.to_i
    clear_screen
  end

  def valid_bet?(input)
    valid_positive_int?(input) && possible_bet?(input)
  end

  def possible_bet?(bet)
    bet.to_i <= human.chips
  end

  def bet_error(bet)
    if !valid_positive_int?(bet)
      prompt PROMPTS["invalid_int"]
    else
      prompt PROMPTS["toohigh"]
    end
  end

  def draw_hands
    human.draw_hand
    dealer.draw_hand
  end

  def show_hands
    human.show_hand
    newline
    dealer.show_hand
    newline
  end

  def play_round
    draw_hands
    loop do
      break if blackjack?
      show_hands
      human.take_turn
      break if human.done?
      dealer.take_turn(human.visible_card)
      break if dealer.done?
    end
  end

  def blackjack?
    human.blackjack? || dealer.blackjack?
  end

  def resolve_round
    dealer.reveal
    show_hands
    process_result
    pause
    clear_screen
    update_players
  end

  # rubocop: disable Metrics/MethodLength
  def process_result
    if human.busted?
      self.winner = :dealer
      prompt PROMPTS["you_bust"]
    elsif human.blackjack?
      self.winner = :human
      prompt PROMPTS["blackjack"]
    elsif dealer.busted?
      self.winner = :human
      prompt PROMPTS["you_win"]
    else compare_hands
    end
  end
  # rubocop: enable Metrics/MethodLength

  def compare_hands
    if human > dealer
      self.winner = :human
      prompt PROMPTS["you_win"]
    elsif dealer > human
      self.winner = :dealer
      prompt PROMPTS["you_lose"]
    else
      prompt PROMPTS["tie"]
    end
  end

  def update_players
    human.new_hand
    dealer.new_hand
    human.resolve_bet(winner)
  end

  def game_over?
    human.chips <= 0 || human.chips >= win_total
  end

  def resolve_game
    if human.chips <= 0
      prompt PROMPTS["nochips"]
    elsif human.chips >= win_total
      prompt format(PROMPTS["won"], chips: human.chips)
    end
  end

  def reset_game!
    human.reset!(START_CHIPS)
    dealer.reset!
  end
end

TwentyOneGame.new.play
