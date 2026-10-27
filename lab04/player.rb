require_relative 'board'
require_relative 'errors'

module Battleship
  class Player
    attr_reader :name, :board

    def initialize(name)
      @name = name
      @board = Board.new
    end
  end

  class HumanPlayer < Player
    def get_shot
      print "\n#{@name}, введіть координати для пострілу (наприклад, A5): "
      input = gets.chomp.strip.upcase
      
      unless input.match?(/^[A-J](10|[1-9])$/)
        raise InvalidInputError, "Некоректний формат! Використовуйте літери A-J та цифри 1-10."
      end

      r = input[0].ord - 65
      c = input[1..].to_i - 1

      [r, c]
    end
  end

  class ComputerPlayer < Player
    def initialize(name = "Комп'ютер")
      super(name)
      @available_shots = []
      (0..9).each { |r| (0..9).each { |c| @available_shots << [r, c] } }
      @available_shots.shuffle! # Перемішуємо, щоб постріли були випадковими і без повторів
    end

    def get_shot
      @available_shots.pop
    end
  end
end