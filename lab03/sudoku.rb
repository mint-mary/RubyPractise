class SudokuGame
  def initialize
    @history = []
    @stats = { moves: 0, errors: 0, hints: 0 }
  end

  def start
    puts "        ГРА СУДОКУ         "
    puts "============================="
    
    choose_size
    choose_difficulty
    generate_boards
    
    play
  end

  private

  # Вибір розміру поля
  def choose_size
    loop do
      print "Оберіть розмір поля (4 для 4x4, 9 для 9x9): "
      input = gets.chomp
      if input == '4'
        @size = 4
        @box_size = 2
        break
      elsif input == '9'
        @size = 9
        @box_size = 3
        break
      else
        puts "Помилка! Введіть 4 або 9."
      end
    end
  end

  # Вибір складності гри
  def choose_difficulty
    loop do
      puts "\nОберіть рівень складності:"
      puts "1 - Легкий"
      puts "2 - Середній"
      puts "3 - Складний"
      print "Ваш вибір (1-3): "
      input = gets.chomp.to_i
      if [1, 2, 3].include?(input)
        @difficulty = input
        break
      end
      puts "Помилка! Введіть 1, 2 або 3."
    end
  end

  # Генерація поля на основі базового коректного розв'язку 
  def generate_boards
    # Базові вирішені матриці
    base_4x4 = [
      [1, 2, 3, 4],
      [3, 4, 1, 2],
      [2, 1, 4, 3],
      [4, 3, 2, 1]
    ]

    base_9x9 = [
      [1,2,3, 4,5,6, 7,8,9],
      [4,5,6, 7,8,9, 1,2,3],
      [7,8,9, 1,2,3, 4,5,6],
      [2,3,1, 5,6,4, 8,9,7],
      [5,6,4, 8,9,7, 2,3,1],
      [8,9,7, 2,3,1, 5,6,4],
      [3,1,2, 6,4,5, 9,7,8],
      [6,4,5, 9,7,8, 3,1,2],
      [9,7,8, 3,1,2, 6,4,5]
    ]

    base = @size == 4 ? base_4x4 : base_9x9

    # Перемішування чисел для створення унікального поля
    mapping = (1..@size).to_a.shuffle
    @solution = base.map do |row|
      row.map { |val| mapping[val - 1] }
    end

    @board = @solution.map(&:dup)
    
    remove_count = calculate_cells_to_remove
    remove_cells(remove_count)

    # Збереження початкового стану 
    @initial_board = @board.map(&:dup)
  end

  def calculate_cells_to_remove
    if @size == 4
      [4, 6, 9][@difficulty - 1] # Кількість порожніх клітинок для 4x4
    else
      [30, 45, 55][@difficulty - 1] # Кількість порожніх клітинок для 9x9
    end
  end

  def remove_cells(count)
    removed = 0
    while removed < count
      r, c = rand(@size), rand(@size)
      if @board[r][c] != 0
        @board[r][c] = 0
        removed += 1
      end
    end
  end

  # Відображення ігрового поля
  def print_board
    puts "\n    " + (1..@size).to_a.join(" ")
    puts "  " + "-" * (@size * 2 + 1)
    
    @board.each_with_index do |row, i|
      print "#{i + 1} | "
      row.each_with_index do |cell, j|
        print cell == 0 ? ". " : "#{cell} "
        print "| " if (j + 1) % @box_size == 0 && j != @size - 1
      end
      puts
      if (i + 1) % @box_size == 0 && i != @size - 1
        puts "  " + "-" * (@size * 2 + 1)
      end
    end
    puts
  end

  # Основний ігровий цикл
  def play
    loop do
      print_board
      if check_win
        puts "ВІТАЄМО! Ви успішно розв'язали Судоку!"
        print_stats
        break
      end

      puts "  Керування:"
      puts "  [Рядок] [Стовпець] [Число] - зробити хід (напр. '1 2 4')"
      puts "  'u' - скасувати останній хід (undo)"
      puts "  'h' - підказка (hint)"
      puts "  'q' - вийти з гри достроково"
      print "\nВаш вибір: "
      
      input = gets.chomp.downcase

      case input
      when 'q'
        puts "Гру перервано. До зустрічі!"
        print_stats
        break
      when 'u'
        undo_move
      when 'h'
        give_hint
      else
        process_move(input)
      end
    end
  end

  # Обробка ходу
  def process_move(input)
    parts = input.split
    if parts.length == 3 && parts.all? { |p| p.match?(/^\d+$/) }
      r, c, v = parts.map(&:to_i)
      
      if r < 1 || r > @size || c < 1 || c > @size
        puts "Помилка: Рядок і стовпець мають бути від 1 до #{@size}."
        @stats[:errors] += 1
        return
      end

      if v < 1 || v > @size
        puts "Помилка: Число має бути від 1 до #{@size}."
        @stats[:errors] += 1
        return
      end

      r_idx, c_idx = r - 1, c - 1

      if @initial_board[r_idx][c_idx] != 0
        puts "Помилка: Цю клітинку не можна змінювати (це початкове число)."
        @stats[:errors] += 1
        return
      end

      temp_val = @board[r_idx][c_idx]
      @board[r_idx][c_idx] = 0 

      if valid_placement?(r_idx, c_idx, v)
        @history.push({ r: r_idx, c: c_idx, prev: temp_val })
        @board[r_idx][c_idx] = v
        @stats[:moves] += 1
        puts "Хід прийнято!"
      else
        @board[r_idx][c_idx] = temp_val # Відкат
        puts "Помилка: Число #{v} порушує правила (повторюється в рядку, стовпці або блоці)."
        @stats[:errors] += 1
      end
    else
      puts "Некоректне введення. Формат: 'Рядок Стовпець Число' (наприклад, 1 2 4)."
      @stats[:errors] += 1
    end
  end

  # Перевірка правильності ходу за правилами
  def valid_placement?(row, col, num)
    # Перевірка рядка
    return false if @board[row].include?(num)
    
    # Перевірка стовпця
    return false if @board.map { |r| r[col] }.include?(num)

    # Перевірка блоку
    start_row = row - row % @box_size
    start_col = col - col % @box_size
    (0...@box_size).each do |i|
      (0...@box_size).each do |j|
        return false if @board[start_row + i][start_col + j] == num
      end
    end

    true
  end

  # Відміна останнього ходу
  def undo_move
    if @history.empty?
      puts "Немає ходів для скасування."
    else
      last_move = @history.pop
      @board[last_move[:r]][last_move[:c]] = last_move[:prev]
      puts "Останній хід скасовано."
    end
  end

  # Підказка гравцеві
  def give_hint
    empty_cells = []
    @board.each_with_index do |row, i|
      row.each_with_index do |cell, j|
        empty_cells << [i, j] if cell == 0
      end
    end

    if empty_cells.empty?
      puts "Поле вже повністю заповнено!"
    else
      r, c = empty_cells.sample
      correct_val = @solution[r][c]
      
      @history.push({ r: r, c: c, prev: 0 })
      @board[r][c] = correct_val
      @stats[:hints] += 1
      
      puts "Підказка: У рядок #{r + 1}, стовпець #{c + 1} вставлено правильне число #{correct_val}."
    end
  end

  # Перевірка перемоги (чи немає нулів на дошці)
  def check_win
    !@board.flatten.include?(0)
  end

  def print_stats
    puts "\n ВАША СТАТИСТИКА:"
    puts "   Успішних ходів: #{@stats[:moves]}"
    puts "   Помилок допущено: #{@stats[:errors]}"
    puts "   Використано підказок: #{@stats[:hints]}"
  end
end

# Запуск гри
SudokuGame.new.start