class GuessTheNum
  
  def play_game()
    puts "Guess a number between 1 and 100 "
    rand_number = rand(1..100)
    attempts = 0

    loop do 
      print "Enter your guess: "
      raw_input = gets.chomp
      if !raw_input.match?(/^[0-9]+$/)
        puts "Invalid input. Please enter a valid number."
        next
      end

      assumption = raw_input.to_i 
      attempts += 1

      if assumption < 1 || assumption > 100
        puts "Your guess is out of range. Please guess a number between 1 and 100."

      elsif assumption < rand_number
        puts "Your guess is too low. Try again."

      elsif assumption > rand_number
        puts "Your guess is too high. Try again."
      elsif assumption == rand_number
        puts "Congratulations! You guessed the number - #{rand_number}. You made #{attempts} attempts."
        break
      end
    end
  end
  
end

GuessTheNum.new.play_game