def cut_cake(cake)
  # Перетворюємо вхідний рядок у 2D масив символів
  grid = cake.strip.split("\n").map(&:chars)
  height = grid.size
  return [] if height == 0
  width = grid[0].size

  # Рахуємо загальну кількість родзинок
  raisins = grid.sum { |row| row.count('o') }
  
  return [] if raisins == 0 || (height * width) % raisins != 0

  # Площа одного шматка
  area = (height * width) / raisins

  # Знаходимо всі можливі розміри (висота, ширина) для шматка заданої площі
  dims = (1..area).select { |r| area % r == 0 }.map { |r| [r, area / r] }

  solutions = []
  covered = Array.new(height) { Array.new(width, false) }

  # Рекурсивна функція для пошуку всіх можливих розрізів
  solve = lambda do |r, c, current_pieces|
    # Знаходимо наступну вільну клітинку
    while r < height && covered[r][c]
      c += 1
      if c == width
        c = 0
        r += 1
      end
    end

    # Якщо всі клітинки покриті рішення знайдено
    if r == height
      solutions << current_pieces.dup
      return
    end

    # Пробуємо підставити кожен можливий розмір прямокутника
    dims.each do |dh, dw|
      next if r + dh > height || c + dw > width

      valid = true
      rcount = 0

      # Перевіряємо, чи не перекриває він інші шматки та скільки має родзинок
      (r...r+dh).each do |rr|
        (c...c+dw).each do |cc|
          if covered[rr][cc]
            valid = false
            break
          end
          rcount += 1 if grid[rr][cc] == 'o'
        end
        break unless valid
      end

      # Якщо шматок валідний і містить рівно 1 родзинку
      if valid && rcount == 1
        # Позначаємо клітинки як зайняті
        (r...r+dh).each { |rr| (c...c+dw).each { |cc| covered[rr][cc] = true } }

        # Формуємо рядок для шматка
        piece_rows = []
        (r...r+dh).each do |rr|
          piece_rows << grid[rr][c...c+dw].join
        end
        current_pieces << piece_rows.join("\n")

        # Рекурсивний виклик для наступних клітинок
        solve.call(r, c, current_pieces)

        # Відкочуємо зміни (backtracking)
        current_pieces.pop
        (r...r+dh).each { |rr| (c...c+dw).each { |cc| covered[rr][cc] = false } }
      end
    end
  end

  solve.call(0, 0, [])

  # Серед усіх знайдених рішень обираємо те, де ширина ПЕРШОГО шматка є максимальною
  solutions.max_by { |sol| sol.first.split("\n").first.size } || []
end

cakes = {
  "Приклад 1 (Пріоритет горизонтального розрізу)" => %(
.o......
......o.
....o...
..o.....
  ),

  "Приклад 2 (Різні форми шматків, площа 12)" => %(
.o.o....
........
....o...
........
.....o..
........
  ),

  "Тест 3 (Маленький квадрат 4x4, 4 родзинки)" => %(
o...
..o.
....
o..o
  ),

  "Тест 4 (Вузький і довгий, 3 родзинки)" => %(
.o.
o..
..o
  ),

  "Тест 5 (Родзинки скупчені в одному куті)" => %(
oo..
oo..
....
....
  )
}

cakes.each do |name, cake_string|
  # Очищаємо зайві порожні рядки на початку/вкінці для чистоти тесту
  clean_cake = cake_string.strip
  
  puts "=== #{name} ==="
  puts "Торт:"
  puts clean_cake
  
  result = cut_cake(clean_cake)
  
  puts "\nРезультат:"
  if result.empty?
    puts "Рішення не знайдено!"
  else
    puts "[\n"
    result.each_with_index do |piece, index|
      puts piece.split("\n").map { |line| "  #{line}" }.join("\n")
      puts "," unless index == result.size - 1
    end
    puts "]\n"
  end
  puts "\n"
end