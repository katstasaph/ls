require 'yaml'
PROMPTS = YAML.load_file('rps_prompts.yml')

MOVES_STORED = 3
ACH_TOTAL_LOW = 3
ACH_TOTAL_MED = 5
ACH_TOTAL_HIGH = 20

SPECIAL_INPUT = ["rules", "stats"]
QUIT_INPUT = ["q", "quit", "x", "exit"]
ALIASES = { r: "rock", sc: "scissors", p: "paper", sp: "spock", l: "lizard" }
WINNERS = {
  rock: {
    "lizard" => ["crushes", "flattens", "squashes"],
    "scissors" => ["breaks", "cracks", "smashes"]
  },
  scissors: {
    "lizard" => ["beheads", "disembowels", "eviscerates"],
    "paper" => ["cuts", "shreds", "snips"]
  },
  paper: {
    "rock" => ["covers", "hides", "smothers"],
    "spock" => ["disproves", "outsmarts", "stumps"]
  },
  spock: {
    "rock" => ["pulverizes", "vaporizes", "zaps"],
    "scissors" => ["destroys", "disintegrates", "lasers"]
  },
  lizard: {
    "paper" => ["chews", "devours", "digests"],
    "spock" => ["bites", "poisons", "scratches"]
  }
}

def prompt(input)
  puts ">> #{input}"
end

def clear_screen
  system "clear"
end

def prompt_yes_or_no
  input = nil
  loop do
    input = gets.chomp.downcase.gsub(/\./, '')
    break if yes?(input) || no?(input)
    prompt PROMPTS["yesno"]
  end
  input
end

def yes?(input)
  accepted_inputs = ["y", "yes"]
  accepted_inputs.include?(input)
end

def no?(input)
  accepted_inputs = ["n", "no"]
  accepted_inputs.include?(input)
end

def show_rules
  clear_screen
  prompt PROMPTS["rules"]
  prompt PROMPTS["enter"]
  gets
  clear_screen
end

def show_stats(stats)
  clear_screen

  show_total_rounds(stats)
  show_total_moves(stats)
  show_move_stats(stats)
  show_achievements(stats)

  prompt PROMPTS["enter"]
  gets
  clear_screen
end

def show_total_rounds(stats)
  prompt format(PROMPTS["total_rounds"], rounds: stats[:rounds])
end

def show_total_moves(stats)
  prompt format(
    PROMPTS["total_moves"],
    rock: stats[:rock],
    paper: stats[:paper],
    scissors: stats[:scissors],
    spock: stats[:spock],
    lizard: stats[:lizard]
  )
end

def format_moves(moves)
  if moves.length > 0
    moves.join(", ")
  else
    PROMPTS["noneyet"]
  end
end

def show_move_stats(stats)
  your_moves = format_moves(stats[:your_moves])
  computer_moves = format_moves(stats[:computer_moves])
  prompt format(PROMPTS["your_moves"], moves: your_moves)
  prompt format(PROMPTS["computer_moves"], moves: computer_moves)
end

def show_achievements(stats)
  list = ""
  prompt PROMPTS["achievements"]
  stats[:achievements].each do |key, data|
    if data[:done]
      message = get_achievement_name(key)
      string_to_add = format_achievement(data[:threshold], message) + "\n"
      list += string_to_add + "   "
    end
  end
  list_achievements(list)
end

def list_achievements(list)
  if list.length > 0
    prompt list + "\n"
  else
    prompt PROMPTS["noneyet"]
  end
end

def get_achievement_name(name)
  name.to_s
end

def format_achievement(total, message)
  format(PROMPTS[message], total: total.to_s)
end

def get_victory_total
  total = nil
  prompt PROMPTS["victory"]
  loop do
    total = gets.chomp
    break if valid_positive_int?(total)
    prompt PROMPTS["invalid_int"]
  end
  total
end

def valid_positive_int?(input)
  input.to_i.to_s == input && input.to_i > 0
end

def reset_scores!(scores)
  scores.transform_values! { 0 }
end

# Reset total rounds, plays, and move history.
# But don't reset achievement stats -- they are persistent
def reset_stats!(stats)
  stats.transform_values! do |value|
    if value.is_a?(Integer)
      0
    elsif value.is_a?(Array)
      []
    else
      value
    end
  end
end

def parse_player_move(stats)
  input = nil
  loop do
    input = gets.chomp.downcase
    if handle_special_commands(input, stats)
      next
    end
    break if valid_move?(input)
    prompt PROMPTS["reenter"]
  end
  convert_abbreviation(input)
end

def handle_special_commands(input, stats)
  special = SPECIAL_INPUT.include?(input)
  quit = QUIT_INPUT.include?(input)
  return unless special || quit
  if input == "rules"
    show_rules
  elsif input == "stats"
    show_stats(stats)
  elsif quit
    quit_game
  end
  prompt PROMPTS["select_move"]
  true
end

def valid_move?(input)
  ALIASES.keys.include?(input.to_sym) || ALIASES.values.include?(input)
end

def convert_abbreviation(input)
  input = input.to_sym
  ALIASES[input]
end

def get_computer_move
  ALIASES.values.sample
end

def determine_winner(player_move, computer_move)
  if won?(player_move, computer_move)
    "player"
  elsif won?(computer_move, player_move)
    "computer"
  else
    "tie"
  end
end

def won?(first_player, second_player)
  WINNERS[first_player.to_sym].keys.include?(second_player)
end

def update_score_stats!(scores, stats, outcome)
  case outcome
  when "player"
    scores[:player] += 1
    update_consecutive_wins!(stats)
  when "computer"
    scores[:computer] += 1
    update_consecutive_losses!(stats)
  else
    update_consecutive_ties!(stats)
  end
end

def update_consecutive_wins!(stats)
  stats[:consecutive_wins] += 1
  stats[:consecutive_losses] = 0
  stats[:consecutive_ties] = 0
end

def update_consecutive_losses!(stats)
  stats[:consecutive_losses] += 1
  stats[:consecutive_wins] = 0
  stats[:consecutive_ties] = 0
end

def update_consecutive_ties!(stats)
  stats[:consecutive_ties] += 1
  stats[:consecutive_wins] = 0
  stats[:consecutive_losses] = 0
end

def update_stats!(stats, you, computer)
  stats[:rounds] += 1
  update_your_stats!(stats, you)
  update_computer_stats!(stats, computer)
end

def update_your_stats!(stats, you)
  update_move_totals!(stats, you)
  update_last_moves!(stats, you, :your_moves)
end

def update_move_totals!(stats, move)
  stats[move.to_sym] += 1
end

def update_computer_stats!(stats, computer)
  update_last_moves!(stats, computer, :computer_moves)
end

def update_last_moves!(stats, move, key)
  stats[key] << move
  if stats[key].length > MOVES_STORED
    stats[key].shift
  end
end

def update_all_achievements!(stats)
  stats[:achievements].each do |_key, value|
    stat = value[:track].to_sym
    if stats[stat] >= value[:threshold]
      value[:done] = true
    end
  end
end

def unlock_achievements!(stats)
  stats[:achievements].each do |key, data|
    if data[:done]
      unless data[:shown]
        message = get_achievement_name(key)
        prompt(
          "*** " +
          PROMPTS["unlocked"] +
          format_achievement(data[:threshold], message) +
          " ***\n\n"
        )
        data[:shown] = true
      end
    end
  end
end

def print_round_intro(round, total)
  prompt format(PROMPTS["current_round"], round: round)
  prompt format(PROMPTS["playing_to"], total: total)
end

def print_moves(player_move, computer_move)
  prompt "Your move: #{player_move}."
  prompt "Computer move: #{computer_move}.\n\n"
end

def print_score(scores)
  prompt "Your score is: #{scores[:player]}.\n" \
             "   Computer's score is: #{scores[:computer]}.\n\n"
end

def print_victory_message(player_move, computer_move, outcome)
  case outcome
  when "player"
    verb = get_verb(player_move, computer_move)
    prompt "*** #{player_move.capitalize} #{verb} #{computer_move}. " \
    "You win! *** \n\n"
  when "computer"
    verb = get_verb(computer_move, player_move)
    prompt "*** #{computer_move.capitalize} #{verb} #{player_move}. " \
    "You lose. ***\n\n"
  else
    prompt "Tie!"
  end
end

def get_verb(first_move, second_move)
  WINNERS[first_move.to_sym].each do |key, value|
    if key == second_move
      return value.sample
    end
  end
  "beats"
end

def quit_game
  prompt PROMPTS["end"]
  exit
end

def play_game(scores, stats)
  reset_scores!(scores)
  reset_stats!(stats)
  total = get_victory_total.to_i
  run_game(scores, stats, total)
end

def run_game(scores, stats, total)
  round = 1
  while scores[:player] < total && scores[:computer] < total
    prompt PROMPTS["select_move"]
    player_move = parse_player_move(stats)
    computer_move = get_computer_move
    clear_screen

    print_round_intro(round, total)
    print_moves(player_move, computer_move)

    outcome = determine_winner(player_move, computer_move)
    update_score_stats!(scores, stats, outcome)
    update_stats!(stats, player_move, computer_move)

    print_victory_message(player_move, computer_move, outcome)
    handle_post_round(scores, stats)

    round += 1
  end
end

def handle_post_round(scores, stats)
  print_score(scores)
  handle_achievements!(stats)
end

def handle_achievements!(stats)
  update_all_achievements!(stats)
  unlock_achievements!(stats)
end

def play_again?
  prompt PROMPTS["restart"]
  input = prompt_yes_or_no
  yes?(input)
end

scores = {
  player: 0,
  computer: 0
}

stats = {
  rounds: 0,
  rock: 0,
  paper: 0,
  scissors: 0,
  spock: 0,
  lizard: 0,
  your_moves: [],
  computer_moves: [],
  consecutive_wins: 0,
  consecutive_losses: 0,
  consecutive_ties: 0,
  achievements: {
    achievement_rock: {
      track: "rock",
      threshold: ACH_TOTAL_MED,
      done: false,
      shown: false
    },
    achievement_paper: {
      track: "paper",
      threshold: ACH_TOTAL_MED,
      done: false,
      shown: false
    },
    achievement_scissors: {
      track: "scissors",
      threshold: ACH_TOTAL_MED,
      done: false,
      shown: false
    },
    achievement_spock: {
      track: "spock",
      threshold: ACH_TOTAL_MED,
      done: false,
      shown: false
    },
    achievement_lizard: {
      track: "lizard",
      threshold: ACH_TOTAL_MED,
      done: false,
      shown: false
    },
    achievement_fallacy: {
      track: "consecutive_losses",
      threshold: ACH_TOTAL_MED,
      done: false,
      shown: false
    },
    achievement_hubris: {
      track: "consecutive_wins",
      threshold: ACH_TOTAL_MED,
      done: false,
      shown: false
    },
    achievement_tension: {
      track: "consecutive_ties",
      threshold: ACH_TOTAL_LOW,
      done: false,
      shown: false
    },
    achievement_time: {
      track: "rounds",
      threshold: ACH_TOTAL_HIGH,
      done: false,
      shown: false
    }
  }
}

clear_screen
prompt PROMPTS["intro"]

rules = prompt_yes_or_no
if yes?(rules)
  show_rules
end

loop do
  play_game(scores, stats)
  break unless play_again?
end
quit_game
