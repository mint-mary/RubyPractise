class RockPaperScissors
    def play_game()
            user_win_count = 0
            computer_win_count = 0
            ties_count = 0
            rounds = 0

            win_conditions = {
              "Rock" => "Scissors",
              "Paper" => "Rock",
              "Scissors" => "Paper"
            }
            
            loop do
              puts "Choose your move:"
              puts "1 = Rock"
              puts "2 = Paper"
              puts "3 = Scissors"
              puts "0 = Exit"

              choices = ["Rock", "Paper", "Scissors"]  

              raw_input = gets.chomp

              if !["0", "1", "2", "3"].include?(raw_input)
                puts "Invalid choice. Please choose a number between 0 and 3."
                next     
              end

              if raw_input == "0"
                puts "Exiting the game"
                break
              end

              user_choice = choices[raw_input.to_i - 1]
              computer_choice = choices.sample
              puts "you chose #{user_choice}, computer chose #{computer_choice}"

              if user_choice == computer_choice
                  puts "It's a tie!"
                  ties_count += 1
              elsif win_conditions[user_choice] == computer_choice
                  puts "You win!"
                  user_win_count += 1
              else
                  puts "Computer wins!"
                  computer_win_count += 1
              end
              rounds += 1
              
              puts "--- Current Stats ---"
              puts "You won #{user_win_count}"
              puts "Computer won #{computer_win_count}"
              puts "Ties: #{ties_count}"
              puts "Total rounds: #{rounds}"
            end
    end
end

RockPaperScissors.new.play_game