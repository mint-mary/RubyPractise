require_relative 'game'

stats = { wins: 0, losses: 0 }

def show_rules
  puts "\n=== ПРАВИЛА ГРИ 'МОРСЬКИЙ БІЙ' ==="
  puts "1. Поле розміром 10x10, координати від A1 до J10."
  puts "2. Кораблі: 1x4, 2x3, 3x2, 4x1 (розставляються автоматично)."
  puts "3. Легенда:"
  puts "   . - невідома або порожня клітинка"
  puts "   O - ваш цілий корабель"
  puts "   X - влучання у корабель"
  puts "   * - промах (постріл у воду)"
  puts "4. Мета: знищити всі кораблі супротивника."
  puts "====================================\n"
end

loop do
  puts "\n--- ГОЛОВНЕ МЕНЮ ---"
  puts "Статистика: Перемог - #{stats[:wins]} | Поразок - #{stats[:losses]}"
  puts "1. Почати нову гру"
  puts "2. Правила гри"
  puts "3. Вихід"
  print "Оберіть опцію (1-3): "
  
  choice = gets.chomp.strip

  case choice
  when '1'
    game = Battleship::Game.new
    result = game.play
    stats[:wins] += 1 if result == :win
    stats[:losses] += 1 if result == :loss
  when '2'
    show_rules
  when '3'
    puts "Дякуємо за гру! До зустрічі."
    break
  else
    puts "Невідома команда. Будь ласка, введіть 1, 2 або 3."
  end
end