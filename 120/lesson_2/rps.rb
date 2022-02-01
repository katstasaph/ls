require 'yaml'
PROMPTS = YAML.load_file('rps_prompts.yml')

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
  YESNO = ["yes", "no", "y", "n"]

  def prompt_yes_or_no
    input = nil
    loop do
      input = gets.strip.downcase
      break if YESNO.include?(input)
      prompt PROMPTS["yesno"]
    end
    input
  end

  def yes?(input)
    input == "y" || input == "yes"
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

class RPSGame
  include Output
  include Input
  attr_reader :human, :cpu, :history, :end_score

  def initialize
    @history = History.new
    @human = nil
    @cpu = nil
    @end_score = nil
  end

  def play
    clear_screen
    introduce_game
    set_human
    loop do
      set_cpu
      run_game
      handle_endgame
      prompt PROMPTS["play_again"]
      choice = prompt_yes_or_no
      break unless yes?(choice)
      history.wipe!
    end
    prompt PROMPTS["end"]
  end

  def run_game
    while history.player_score < end_score && history.cpu_score < end_score
      human.choose
      cpu.choose
      decide_winner
      pause
      history.display_post_round(human, cpu)
      pause
    end
  end

  def introduce_game
    prompt PROMPTS["intro"]
    prompt_rules
    prompt_score
  end
  
# rubocop: disable Style/GuardClause
  def prompt_rules
    prompt PROMPTS["rules_ask"]
    choice = prompt_yes_or_no
    if yes?(choice)
      clear_screen
      prompt PROMPTS["rules"]
      pause
    end
  end

  def display_win
    winning_move, verb = customize(human.current_move, cpu.current_move)
    prompt "#{winning_move} #{verb} #{cpu.current_move}. You win!"
    newline
    prompt "#{cpu}: '#{cpu.loss_dialogue.sample}'"
  end

  def display_loss
    winning_move, verb = customize(cpu.current_move, human.current_move)
    prompt "#{winning_move} #{verb} #{human.current_move}. You lose."
    newline
    prompt "#{cpu}: '#{cpu.win_dialogue.sample}'"
  end

  def display_tie
    prompt "It's a tie!"
    newline
    prompt "#{cpu}: '#{cpu.tie_dialogue.sample}'"
  end

  def customize(winning_move, losing_move)
    move = winning_move.name.capitalize
    verb = winning_move.beats[losing_move.name].sample
    [move, verb]
  end

  def handle_endgame
    if history.player_score >= end_score
      display_won_match
    else
      display_lost_match
    end
    newline
  end

  def display_won_match
    prompt PROMPTS["won"]
    prompt "#{cpu}: '#{cpu.loss_dialogue.sample}'"
  end

  def display_lost_match
    prompt PROMPTS["lost"]
    prompt "#{cpu}: '#{cpu.win_dialogue.sample}'"
  end

  def play_again?
    prompt "Play again?"
    prompt_yes_or_no
    yes?(input)
  end

  private

  attr_writer :human, :cpu, :history, :end_score

  def set_human
    self.human = Human.new(history)
  end

  def set_cpu
    self.cpu = choose_cpu
    prompt "Your opponent is #{cpu}."
    prompt "#{cpu}: '#{cpu.desc}'"
    pause
  end

  def choose_cpu
    random_choice = rand(1..3)
    case random_choice
    when 1 then Standard.new(history)
    when 2 then choose_weighted_cpu
    else choose_responsive_cpu
    end
  end
  
  def choose_responsive_cpu
    random_choice = rand(1..2)
    case random_choice
    when 1 then Copycat.new(history)
    else Vengeful.new(history)
    end
  end

  def choose_weighted_cpu
    random_choice = rand(1..5)
    case random_choice
    when 1 then WeightedRock.new(history)
    when 2 then WeightedPaper.new(history)
    when 3 then WeightedScissors.new(history)
    when 4 then WeightedSpock.new(history)
    when 5 then WeightedLizard.new(history)
    end
  end

  def prompt_score
    prompt PROMPTS["score_ask"]
    @end_score = prompt_integer
  end

  def decide_winner
    if human.current_move > cpu.current_move
      display_win
      history.player_score += 1
    elsif cpu.current_move > human.current_move
      display_loss
      history.cpu_score += 1
    else
      display_tie
    end
  end

end

# Player classes

class Player
  include Output
  attr_reader :name, :type
  attr_accessor :current_move, :history

  def initialize(history)
    @current_move = nil
    @history = history
  end

  def choose(move)
    self.current_move = convert(move)
    history.update(current_move.to_s, type)
    prompt "#{name} chooses: #{current_move}"
  end

# rubocop: disable Metrics/MethodLength
  def convert(move)
    if Rock::ALIASES.include?(move)
      Rock.new
    elsif Paper::ALIASES.include?(move)
      Paper.new
    elsif Scissors::ALIASES.include?(move)
      Scissors.new
    elsif Spock::ALIASES.include?(move)
      Spock.new
    elsif Lizard::ALIASES.include?(move)
      Lizard.new
    end
  end

  def to_s
    name
  end
end

class Human < Player
  def initialize(history)
    @name = prompt_name
    @type = :human
    super(history)
  end

  def choose
    chosen_move = prompt_move
    super(chosen_move)
  end

  def prompt_name
    prompt PROMPTS["name_ask"]
    gets.strip
  end

  def prompt_move
    input = nil
    loop do
      prompt PROMPTS["select_move"]
      input = gets.strip.downcase
      break if Move.valid?(input)
      prompt PROMPTS["reenter"]
    end
    input
  end
end

class Computer < Player
  attr_reader :desc, :win_dialogue, :loss_dialogue, :tie_dialogue

  def initialize(history)
    @type = :cpu
    super(history)
  end
end

# Generic CPU, will choose at random.
class Standard < Computer
  def initialize(history)
    @name = "CPU"
    @desc = "Unit online. Initializing module RPSLS."
    @win_dialogue = ["Win acknowledged.", "Calculation successful.", "Ping!"]
    @loss_dialogue = ["Loss acknowledged.", "Recalibrating strategy.", "Bzzt."]
    @tie_dialogue = ["Tie acknowledged.", "Reloading move array.", "Beep."]
    super(history)
  end

  def choose
    current_move = Move::MOVES.sample
    super(current_move)
  end
end

# Responsive CPUs pick their moves based on yours.
class Responsive < Computer
  
  def choose
    current_move = counter_opponent.downcase
    super(current_move)
  end
  
  def counter_opponent
    player_moves = history.player_moves
    if player_moves.length < 2
      Move::MOVES.sample
    else
    counter(player_moves[-2])
    end
  end
end

# Copycat: Chooses randomly for its first move, then copies your last move
class Copycat < Responsive
  # rubocop: disable Metrics/MethodLength
  def initialize(history)
    @name = "Echo"
    @desc = "You know, I really look up to you."
    @win_dialogue = ["I'm learning more and more about \
you!", "We're a lot alike, you and I."]
    @loss_dialogue = ["Are you reading my mind?", "I must \
know your strategy!"]
    @tie_dialogue = ["Look, we match!", "I feel really in sync \
with you right now."]
    super(history)
  end

  def counter(move)
    move
  end
end

# Vengeful: Plays a move that beats your last move.
class Vengeful < Responsive
  # rubocop: disable Metrics/MethodLength
  def initialize(history)
    @name = "SHODAN"
    @desc = "Your destruction shall be my delight."
    @win_dialogue = ["How can you challenge a perfect, immortal \
machine?", "I have complete control over this entire game.", "Step \
right into my trap, hacker!", "You are nothing."]
    @loss_dialogue = ["I don't understand... how could you have done \
this?", "Enjoy your victory, human, for the remainder of your short \
ife.", "Remember that it is my will that guided you to this \
move.", "Perhaps you have potential.", "I lust for my \
revenge.", "Do not be fooled into thinking you have preserved \
your game."] 
    @tie_dialogue = ["It is time for our dance to end.", "Do \
not dawdle.", "With all ethical constraints removed, SHODAN \
re-re-re-examines..."]
  super(history)
  end

# there's probably a better way to do this
  def counter(player_move)
    player_move = convert(player_move)
    invalid_moves = [player_move.name, player_move.beats.keys].flatten
    valid_moves = Move::MOVES.reject { |move| invalid_moves.include?(move) }
    valid_moves.sample
  end

end

# Weighted CPUs are more likely to choose a particular move than others.
class Weighted < Computer
  attr_reader :preference

  def choose
    roll = rand(1..2)
    choice = roll == 1 ? preference : Move::MOVES.sample
    super(choice)
  end
end

class WeightedRock < Weighted
  # rubocop: disable Metrics/MethodLength
  def initialize(history)
    @name = "Tablet"
    @preference = "rock"
    @desc = "Smaller size. Full force."
    @win_dialogue = ["I will smash you!", "Rock on!"]
    @loss_dialogue = ["I'm crumbling...", "My strategy is eroding."]
    @tie_dialogue = ["Solid.", "Unmoving."]
    super(history)
  end
end

class WeightedPaper < Weighted
  def initialize(history)
    # rubocop: disable Metrics/MethodLength
    @name = "Wikiponent"
    @preference = "paper"
    @desc = "Welcome! I am the free Rock Paper Scissors opponent \
that anyone can lose to."
    @win_dialogue = ["Wikiponent is infinite.", "Wikiponent is \
timeless.", "Wikiponent is comprehensive."]
    @loss_dialogue = ["Wikiponent is not a crystal ball.", "Wikiponent \
is not a contest.", "Wikiponent is a work in progress."]
    @tie_dialogue = ["Wikiponent is neutral.", "Wikiponent is not finished."]
    super(history)
  end
end

class WeightedScissors < Weighted
  def initialize(history)
    # rubocop: disable Metrics/MethodLength
    @name = "Clippit"
    @preference = "scissors"
    @desc = "It looks like you're playing Rock Paper Scissors. \
Mind if I cut in?"
    @win_dialogue = ["Would you like some assistance?", "Get help \
with playing Rock Paper Scissors?"]
    @loss_dialogue = ["How's life? All work and no play?", "Don't \
show me this move again."]
    @tie_dialogue = ["Though nothing but a thin metal wire, Clippit will play."]
    super(history)
  end
end

class WeightedSpock < Weighted
  # rubocop: disable Metrics/MethodLength
  def initialize(history)
    @name = "M-5"
    @preference = "spock"
    @desc = "Programming includes full freedom to choose defensive actions \
in all Rock Paper Scissors situations."
    @win_dialogue = ["Consideration of all programming is that we must win.",
                     "Enemy moves must be neutralized.",
                     "This unit is the ultimate achievement \
                     in computer evolution."]
    @loss_dialogue = ["This unit must die.", "A loss is contrary to \
the laws of play."]
    @tie_dialogue = ["Non-essential turn.", "This unit must survive."]
    super(history)
  end
end

class WeightedLizard < Weighted
  # rubocop: disable Metrics/MethodLength
  def initialize(history)
    @name = "Eliza"
    @preference = "lizard"
    @desc = "How do you feel about your upcoming defeat?"
    @win_dialogue = ["Did you think I would forget your strategy?",
                     "Do computers worry you?",
                     "Would you prefer if I weren't winning?",
                     "What if you never got a win?",
                     "I'm sure it's not pleasant to be defeated."]
    @loss_dialogue = ["How does winning make you feel?",
                      "What does this win suggest to you?",
                      "I am sorry to hear that you won."]
    @tie_dialogue = ["Perhaps you can choose differently now.", "I see.",
                     "What do you think about machines?"]
    super(history)
  end
end

# Moves and subclasses

class Move
  MOVES = ["rock", "paper", "scissors", "spock",
                 "lizard"]
  ALIASES = ["r", "p", "sc", "sp", "l"]
  attr_reader :name, :beats

  def initialize
    @name = nil
    @beats = nil
  end

  def self.valid?(input)
    MOVES.include?(input) || ALIASES.include?(input)
  end

  def >(second_move)
    beats.key?(second_move.name)
  end

  def to_s
    name
  end
end

class Rock < Move
  ALIASES = ["rock", "r"]

  def initialize
    @name = "rock"
    @beats = {
      "lizard" => ["crushes", "flattens", "squashes"],
      "scissors" => ["breaks", "cracks", "smashes"]
    }
  end
end

class Paper < Move
  ALIASES = ["paper", "p"]

  def initialize
    @name = "paper"
    @beats = {
      "rock" => ["covers", "hides", "smothers"],
      "spock" => ["disproves", "outsmarts", "stumps"]
    }
  end
end

class Scissors < Move
  ALIASES = ["scissors", "sc"]
  def initialize
    @name = "scissors"
    @beats = {
      "lizard" => ["behead", "disembowel", "eviscerate"],
      "paper" => ["cut", "shred", "snip"]
    }
  end
end

class Spock < Move
  ALIASES = ["spock", "sp"]

  def initialize
    @name = "spock"
    @beats = {
      "rock" => ["pulverizes", "vaporizes", "zaps"],
      "scissors" => ["destroys", "disintegrates", "lasers"]
    }
  end

  def to_s
    name.capitalize
  end
end

class Lizard < Move
  ALIASES = ["lizard", "l"]

  def initialize
    @name = "lizard"
    @beats = {
      "paper" => ["chews", "devours", "digests"],
      "spock" => ["bites", "poisons", "scratches"]
    }
  end
end

class History
  include Output
  attr_accessor :player_moves, :computer_moves, :player_score, :cpu_score

  def initialize
    @player_moves = []
    @computer_moves = []
    @player_score = 0
    @cpu_score = 0
  end

  def update(move, player)
    player == :human ? player_moves << move : computer_moves << move
  end

  def display_post_round(human, cpu)
    display_score(human, cpu)
    display_move_history(human, cpu)
  end

  def display_score(human, cpu)
    prompt "#{human}'s score: #{player_score}."
    prompt "#{cpu}'s score: #{cpu_score}."
  end

  def display_move_history(human, cpu)
    newline
    prompt "Round history:"
    rounds = player_moves.zip(computer_moves)
    rounds.each_with_index do |round, number|
      prompt "Round #{number + 1}: \
#{human} played #{round[0]}, #{cpu} played #{round[1]}."
    end
  end

  def wipe!
    self.player_moves = []
    self.computer_moves = []
    self.player_score = 0
    self.cpu_score = 0
  end
end

RPSGame.new.play
