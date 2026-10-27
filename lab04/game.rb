require_relative 'player'
require_relative 'errors'

module Battleship
  class Game
    def initialize
      @human = HumanPlayer.new("Гравець")
      @computer = ComputerPlayer.new
    end

    def play
      current_player = @human
      opponent = @computer

      loop do
        display_boards if current_player == @human

        begin
          r, c = current_player.get_shot
          
          if current_player == @computer
            puts "\nХід комп'ютера: #{(r + 65).chr}#{c + 1}"
          end

          result = opponent.board.shoot(r, c)
          
          case result
          when :sunk
            puts "=> КОРАБЕЛЬ ЗНИЩЕНО!"
          when :hit
            puts "=> ВЛУЧАННЯ!"
          when :miss
            puts "=> ПРОМАХ."
          end

          if opponent.board.all_sunk?
            display_boards
            puts "\nГра завершена! Переможець: #{current_player.name}!"
            return current_player.is_a?(HumanPlayer) ? :win : :loss
          end

          # Зміна черги
          current_player, opponent = opponent, current_player

        rescue BattleshipError => e
          puts "Помилка: #{e.message}"
          retry # Повертає на початок блоку begin для повторного введення
        end
      end
    end

    private

    def display_boards
      puts "\n=== Поле Комп'ютера (Приховано) ==="
      @computer.board.display(hide_ships: true)
      puts "\n=== Ваше Поле ==="
      @human.board.display(hide_ships: false)
    end
  end
end