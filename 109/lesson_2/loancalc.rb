require 'yaml'
PROMPTS = YAML.load_file('loancalc_prompts.yml')

# The regex will match all input that meets the following criteria:
# At least one digit in the string
# Any number of digits containing at most one decimal point
# At most 2 digits after the decimal point
# The method will return false if these criteria are not met.
def valid_float?(input)
  /\d/.match(input) && /^\d*\.?\d*$/.match(input) && input.to_f > 0
end

def valid_positive_int?(input)
  input.to_i.to_s == input && input.to_i != 0
end

def zero?(input)
  input.to_f == 0
end

def prompt(message)
  puts ">> #{message} \n\n"
end

def clear_screen
  system "clear"
end

def confirm_user_input(input)
  prompt format(PROMPTS["confirm_input"], input: input)
  prompt_yes_or_no
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

def get_loan_amount
  loan_amount = nil
  prompt PROMPTS["loan_initial"]
  loop do
    print "$"
    loan_amount = gets.chomp.gsub(/[$,]/, '')
    unless valid_float?(loan_amount)
      prompt PROMPTS["loan_reformat"]
      next
    end
    confirmation = confirm_user_input("$" + loan_amount)
    break if yes?(confirmation)
    prompt PROMPTS["loan_reentry"]
  end
  clear_screen
  loan_amount
end

def get_apr
  apr = nil
  prompt PROMPTS["apr_initial"]
  loop do
    apr = gets.chomp.gsub(/%/, '')
    unless valid_float?(apr) || zero?(apr)
      prompt PROMPTS["apr_reformat"]
      next
    end
    confirmation = confirm_user_input(apr + "%" + " per year")
    break if yes?(confirmation)
    prompt PROMPTS["apr_reentry"]
  end
  clear_screen
  apr
end

def get_duration(duration_type)
  duration_input = nil
  prompt format(PROMPTS["specific_duration"], type: duration_type)
  loop do
    duration_input = gets.chomp
    unless valid_positive_int?(duration_input)
      prompt PROMPTS["duration_reformat"]
      next
    end
    confirmation = confirm_user_input(duration_input + " #{duration_type}")
    break if confirmation == "y" || confirmation == "yes"
    prompt format(PROMPTS["duration_reentry"], type: duration_type)
  end
  clear_screen
  duration_input
end

def prompt_duration_type
  duration_input = nil
  prompt PROMPTS["initial_duration"]
  loop do
    duration_input = gets.chomp
    break if ["1", "2", "months", "years"].include? duration_input
    prompt PROMPTS["onetwo"]
  end
  if duration_input == "1"
    "months"
  elsif duration_input == "2"
    "years"
  end
end

def compute_monthly_payment(loan_amount, apr, duration)
  if zero?(apr)
    (loan_amount.to_f / duration).ceil(2)
  else
    (loan_amount.to_f * (apr / (1 - (1 + apr)**(-duration))))
  end
end

def compute_total_payment(payment, duration)
  (payment * duration).round(2)
end

def compute_total_interest(total, initial)
  total - initial
end

def convert_duration_to_months(type, input)
  if type == "years"
    (input.to_i * 12)
  else
    input.to_i
  end
end

def convert_loan_to_dollars(amount)
  amount.to_f
end

def convert_apr_to_percent(apr)
  (apr.to_f / 12) / 100
end

def show_as_dollars(number)
  format("%.2f", number)
end

def show_loan_info(data)
  show_initial_prompt(data)

  loan_amount = convert_loan_to_dollars(data[:amount])
  apr = convert_apr_to_percent(data[:apr])
  duration = convert_duration_to_months(data[:type], data[:input])

  monthly_payment = compute_monthly_payment(loan_amount, apr, duration)
  payment = compute_total_payment(monthly_payment, duration)
  interest = zero?(apr) ? 0 : compute_total_interest(payment, loan_amount)

  prompt "Your monthly payment will be: " \
             "#{show_as_dollars(monthly_payment)}.\n" \
             "   After #{duration} months, you will have paid: " \
             "$#{show_as_dollars(payment)}.\n" \
             "   The total interest accrued will be: " \
             "$#{show_as_dollars(interest)}."
end

def show_initial_prompt(data)
  prompt "For a $#{data[:amount]} loan with #{data[:apr]}% APR, " \
             "over #{data[:input]} #{data[:type]}:"
end

clear_screen
prompt PROMPTS["intro"]
loop do
  loan_amount = get_loan_amount
  apr = get_apr
  duration_type = prompt_duration_type
  duration_input = get_duration(duration_type)
  loan_data = {
    amount: loan_amount,
    apr: apr,
    input: duration_input,
    type: duration_type
  }
  show_loan_info(loan_data)

  prompt PROMPTS["again"]
  confirmation = prompt_yes_or_no
  break unless yes?(confirmation)
end
prompt PROMPTS["end"]
