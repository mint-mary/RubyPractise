require 'json'
require 'date'

class ExpenseTracker
  DATA_FILE = 'expenses.json'
  CATEGORIES = %w[food transport study entertainment other].freeze

  def initialize
    @expenses = []
    load_data
  end

  def run
    loop do
      print_menu
      print "Оберіть дію (1-7): "
      choice = gets
      break if choice.nil?

      case choice.chomp.strip
      when '1' then add_expense_interactive
      when '2' then view_all_expenses
      when '3' then filter_expenses
      when '4' then delete_expense_interactive
      when '5' then show_statistics
      when '6' then import_from_json_interactive
      when '7'
        puts "\nДо побачення!"
        break
      else
        puts "\n[Помилка] Невідома команда. Будь ласка, оберіть номер від 1 до 7."
      end
    end
  end

  private

  def print_menu
    puts "\n" + "=" * 40
    puts "         EXPENSE TRACKER MENU"
    puts "=" * 40
    puts "1. Додати витрату"
    puts "2. Переглянути всі витрати"
    puts "3. Фільтрація за категорією та періодом"
    puts "4. Видалити витрату за ідентифікатором"
    puts "5. Переглянути статистику"
    puts "6. Імпорт витрат із JSON-файла"
    puts "7. Завершити роботу"
    puts "-" * 40
  end

  # Завантаження даних із захистом від пошкоджень та порожнього файла
  def load_data
    return unless File.exist?(DATA_FILE)

    content = File.read(DATA_FILE).strip
    if content.empty?
      abort("\n[Критична помилка] Файл #{DATA_FILE} порожній. Програму зупинено без перезаписування файла.")
    end

    parsed = JSON.parse(content)
    raise "Кореневий елемент JSON не є масивом." unless parsed.is_a?(Array)

    @expenses = parsed.map { |item| symbolize_and_validate_expense!(item) }
  rescue JSON::ParserError
    abort("\n[Критична помилка] Файл #{DATA_FILE} пошкоджений (невалідний JSON). Програму зупинено без перезаписування файла.")
  rescue StandardError => e
    abort("\n[Критична помилка] Помилка завантаження даних (#{e.message}). Програму зупинено без перезаписування файла.")
  end

  # Збереження даних у файл
  def save_data
    serialized = @expenses.map do |exp|
      {
        'id' => exp[:id],
        'date' => exp[:date],
        'amount_in_kopecks' => exp[:amount_in_kopecks],
        'category' => exp[:category],
        'description' => exp[:description]
      }
    end

    File.write(DATA_FILE, JSON.pretty_generate(serialized))
  rescue StandardError => e
    puts "\n[Помилка] Не вдалося зберегти дані у файл: #{e.message}. Зміни не застосовано."
    raise e
  end

  def symbolize_and_validate_expense!(item)
    raise "Запис має бути об'єктом JSON" unless item.is_a?(Hash)

    id = item['id']
    date_str = item['date']
    amount = item['amount_in_kopecks']
    category = item['category']
    desc = item['description']

    raise "Некоректний id" unless id.is_a?(Integer) && id > 0
    raise "Некоректна дата" unless valid_date?(date_str)
    raise "Некоректна сума" unless amount.is_a?(Integer) && amount > 0
    raise "Некоректна категорія" unless category.is_a?(String) && CATEGORIES.include?(category)
    raise "Некоректний опис" unless desc.is_a?(String) && !desc.strip.empty? && desc.strip.length <= 200

    {
      id: id,
      date: date_str,
      amount_in_kopecks: amount,
      category: category,
      description: desc.strip
    }
  end

  def valid_date?(date_str)
    return false unless date_str.is_a?(String) && date_str.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.strptime(date_str, '%Y-%m-%d')
    true
  rescue ArgumentError
    false
  end

  def parse_strict_date(date_str)
    return nil unless date_str.is_a?(String) && date_str.match?(/\A\d{4}-\d{2}-\d{2}\z/)

    Date.strptime(date_str, '%Y-%m-%d')
  rescue ArgumentError
    nil
  end

  # Генерація унікального ID
  def next_id
    (@expenses.map { |e| e[:id] }.max || 0) + 1
  end

  def deep_copy_expenses(list)
    Marshal.load(Marshal.dump(list))
  end

  # 1. Додавання витрати
  def add_expense_interactive
    puts "\n--- Додавання нової витрати ---"

    print "Введіть дату у форматі YYYY-MM-DD (або залиште порожнім для сьогодні): "
    date_input = gets&.chomp&.strip
    return if date_input.nil?

    date_str = date_input.empty? ? Date.today.strftime('%Y-%m-%d') : date_input
    unless valid_date?(date_str)
      puts "[Помилка] Невірний формат або нереальна дата (очікується YYYY-MM-DD)."
      return
    end

    print "Введіть суму в копійках (наприклад, 12550 для 125.50 грн): "
    amount_input = gets&.chomp&.strip
    return if amount_input.nil?

    unless amount_input.match?(/\A\d+\z/) && amount_input.to_i > 0
      puts "[Помилка] Сума має бути додатним цілим числом копійок."
      return
    end
    amount = amount_input.to_i

    puts "Доступні категорії: #{CATEGORIES.join(', ')}"
    print "Введіть категорію: "
    category = gets&.chomp&.strip&.downcase
    return if category.nil?

    unless CATEGORIES.include?(category)
      puts "[Помилка] Обраної категорії не існує."
      return
    end

    print "Введіть опис (до 200 символів): "
    description = gets&.chomp&.strip
    return if description.nil?

    if description.empty? || description.length > 200
      puts "[Помилка] Опис не може бути порожнім і повинен містити до 200 символів."
      return
    end

    new_expense = {
      id: next_id,
      date: date_str,
      amount_in_kopecks: amount,
      category: category,
      description: description
    }

    old_state = deep_copy_expenses(@expenses)
    @expenses << new_expense

    begin
      save_data
      puts "\n[Успіх] Витрату успішно додано (ID: #{new_expense[:id]})!"
    rescue StandardError
      @expenses = old_state
    end
  end

  # 2. Перегляд усіх витрат
  def view_all_expenses
    if @expenses.empty?
      puts "\nСписок витрат порожній."
      return
    end

    sorted = @expenses.sort_by { |e| [parse_strict_date(e[:date]) || Date.new(0, 1, 1), e[:id]] }
    print_table(sorted)
  end

  def print_table(expenses_list)
    puts "\n" + "-" * 85
    format_str = "%-4s | %-12s | %-12s | %-15s | %-35s"
    puts format(format_str, "ID", "Дата", "Сума (грн)", "Категорія", "Опис")
    puts "-" * 85

    expenses_list.each do |e|
      uah_str = format('%.2f', e[:amount_in_kopecks] / 100.0)
      puts format(format_str, e[:id], e[:date], uah_str, e[:category], e[:description])
    end
    puts "-" * 85
  end

  # 3. Фільтрація за категорією та періодом
  def filter_expenses
    puts "\n--- Фільтрація витрат ---"
    print "Фільтрувати за категорією? (Введіть категорію або залиште порожнім): "
    cat_input = gets&.chomp&.strip&.downcase
    return if cat_input.nil?

    cat_filter = cat_input.empty? ? nil : cat_input
    if cat_filter && !CATEGORIES.include?(cat_filter)
      puts "[Помилка] Такої категорії не існує."
      return
    end

    print "Початкова дата (YYYY-MM-DD) або порожньо: "
    start_str = gets&.chomp&.strip
    return if start_str.nil?

    print "Кінцева дата (YYYY-MM-DD) або порожньо: "
    end_str = gets&.chomp&.strip
    return if end_str.nil?

    start_date = start_str.empty? ? nil : parse_strict_date(start_str)
    end_date = end_str.empty? ? nil : parse_strict_date(end_str)

    if (!start_str.empty? && start_date.nil?) || (!end_str.empty? && end_date.nil?)
      puts "[Помилка] Невірний формат однієї з дат (очікується YYYY-MM-DD)."
      return
    end

    if start_date && end_date && start_date > end_date
      puts "[Помилка] Початкова дата не може бути пізнішою за кінцеву."
      return
    end

    filtered = @expenses.select do |e|
      match_cat = cat_filter.nil? || e[:category] == cat_filter
      e_date = parse_strict_date(e[:date])
      next false if e_date.nil?

      match_start = start_date.nil? || e_date >= start_date
      match_end = end_date.nil? || e_date <= end_date

      match_cat && match_start && match_end
    end

    if filtered.empty?
      puts "\nЗа заданими критеріями витрат не знайдено."
    else
      sorted = filtered.sort_by { |e| [parse_strict_date(e[:date]), e[:id]] }
      print_table(sorted)
    end
  end

  # 4. Видалення витрати за ID із підтвердженням
  def delete_expense_interactive
    if @expenses.empty?
      puts "\nСписок витрат порожній. Нічого видаляти."
      return
    end

    view_all_expenses
    print "\nВведіть ID витрати для видалення: "
    id_input = gets&.chomp&.strip
    return if id_input.nil?

    unless id_input.match?(/\A\d+\z/)
      puts "[Помилка] Некоректний ID витрати."
      return
    end
    id = id_input.to_i

    expense_to_delete = @expenses.find { |e| e[:id] == id }
    unless expense_to_delete
      puts "[Помилка] Витрату з таким ID не знайдено."
      return
    end

    print "Ви дійсно хочете видалити витрату ID #{id}? (y/n): "
    confirm = gets&.chomp&.strip&.downcase
    return if confirm.nil?

    unless confirm == 'y'
      puts "Видалення скасовано."
      return
    end

    old_state = deep_copy_expenses(@expenses)
    @expenses.reject! { |e| e[:id] == id }

    begin
      save_data
      puts "\n[Успіх] Витрату успішно видалено!"
    rescue StandardError
      @expenses = old_state
    end
  end

  # 5. Перегляд статистики
  def show_statistics
    if @expenses.empty?
      puts "\nСтатистика недоступна: список витрат порожній."
      return
    end

    puts "\n" + "=" * 30 + " СТАТИСТИКА " + "=" * 30

    total_kopecks = @expenses.sum { |e| e[:amount_in_kopecks] }
    puts "Загальна сума витрат: #{format('%.2f', total_kopecks / 100.0)} грн"

    puts "\nСума за категоріями:"
    CATEGORIES.each do |cat|
      cat_sum = @expenses.select { |e| e[:category] == cat }.sum { |e| e[:amount_in_kopecks] }
      puts "  - #{cat}: #{format('%.2f', cat_sum / 100.0)} грн"
    end

    max_amount = @expenses.map { |e| e[:amount_in_kopecks] }.max
    max_expenses = @expenses.select { |e| e[:amount_in_kopecks] == max_amount }
    puts "\nНайбільша витрата (#{format('%.2f', max_amount / 100.0)} грн):"
    max_expenses.each do |e|
      puts "  * ID: #{e[:id]} | Дата: #{e[:date]} | Категорія: #{e[:category]} | #{e[:description]}"
    end

    puts "\n--- Статистика за періодом ---"
    print "Введіть початкову дату (YYYY-MM-DD): "
    start_str = gets&.chomp&.strip
    return if start_str.nil?

    print "Введіть кінцеву дату (YYYY-MM-DD): "
    end_str = gets&.chomp&.strip
    return if end_str.nil?

    start_date = parse_strict_date(start_str)
    end_date = parse_strict_date(end_str)

    unless start_date && end_date
      puts "[Помилка] Невірний формат дат (очікується YYYY-MM-DD)."
      return
    end

    if start_date > end_date
      puts "[Помилка] Початкова дата не може бути пізнішою за кінцеву."
      return
    end

    period_expenses = @expenses.select do |e|
      e_date = parse_strict_date(e[:date])
      !e_date.nil? && e_date >= start_date && e_date <= end_date
    end

    if period_expenses.empty?
      puts "За період з #{start_date} по #{end_date} витрат не знайдено. Сума: 0.00 грн"
    else
      period_sum = period_expenses.sum { |e| e[:amount_in_kopecks] }
      puts "Сума за період з #{start_date} по #{end_date}: #{format('%.2f', period_sum / 100.0)} грн"
    end
    puts "=" * 72
  end

  # 6. Імпорт витрат із JSON-файла
  def import_from_json_interactive
    print "\nВведіть шлях до JSON-файлу для імпорту: "
    filepath = gets&.chomp&.strip
    return if filepath.nil?

    if filepath.empty? || !File.exist?(filepath)
      puts "[Помилка] Файл не знайдено."
      return
    end

    imported_array = begin
      content = File.read(filepath)
      JSON.parse(content)
    rescue JSON::ParserError
      puts "[Помилка] Невалідний JSON у файлі імпорту."
      return
    rescue StandardError => e
      puts "[Помилка] Не вдалося прочитати файл імпорту: #{e.message}"
      return
    end

    unless imported_array.is_a?(Array)
      puts "[Помилка] Імпортований файл повинен містити масив записів."
      return
    end

    valid_imported = []
    imported_array.each_with_index do |item, index|
      valid_imported << symbolize_and_validate_expense!(item)
    rescue StandardError => e
      puts "[Помилка] Запис під індексом #{index} пропущено через невалідні дані: #{e.message}"
    end

    if valid_imported.empty?
      puts "[Увага] Жодного валідного запису для імпорту не знайдено."
      return
    end

    old_state = deep_copy_expenses(@expenses)

    valid_imported.each do |item|
      new_item = item.dup
      new_item[:id] = next_id while @expenses.any? { |e| e[:id] == new_item[:id] }
      @expenses << new_item
    end

    begin
      save_data
      puts "\n[Успіх] Успішно імпортовано та збережено #{valid_imported.length} записів!"
    rescue StandardError
      @expenses = old_state
    end
  end
end

# Запуск програми
ExpenseTracker.new.run