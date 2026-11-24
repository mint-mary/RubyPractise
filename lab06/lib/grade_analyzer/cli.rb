# frozen_string_literal: true

module GradeAnalyzer
  class CLI
    INTEGER_REGEX = /\A-?\d+\z/.freeze

    def initialize(repository:, analytics:, report_path:, input: $stdin, output: $stdout)
      @repository = repository
      @analytics = analytics
      @report_path = File.expand_path(report_path)
      @input = input
      @output = output
    end

    def run
      loop do
        print_menu
        choice = prompt("Оберіть пункт меню: ")
        break if choice.nil? # EOF (Ctrl+D)

        case choice.strip
        when "1" then show_all_records
        when "2" then show_student_averages
        when "3" then show_extrema_students
        when "4" then show_subject_averages
        when "5" then search_student
        when "6" then add_grade_flow
        when "7" then edit_grade_flow
        when "8" then delete_grade_flow
        when "9" then save_report_flow
        when "0"
          @output.puts "Вихід із програми. До зустрічі!"
          break
        else
          @output.puts "Невідомий пункт меню. Введіть число від 0 до 9."
        end
      end
    end

    private

    def print_menu
      @output.puts <<~MENU

        ================ АНАЛІЗ УСПІШНОСТІ СТУДЕНТІВ ================
        1. Показати список усіх студентів та оцінок
        2. Розрахувати середній бал кожного студента
        3. Визначити студентів із найвищим та найнижчим середнім балом
        4. Розрахувати середній бал за кожним предметом
        5. Пошук студента за іменем
        6. Додати оцінку (зі збереженням у CSV)
        7. Редагувати оцінку (зі збереженням у CSV)
        8. Видалити оцінку (зі збереженням у CSV)
        9. Сформувати та зберегти статистичний звіт у report.txt
        0. Вихід
        ===============================================================
      MENU
    end

    def prompt(label)
      @output.print(label)
      @output.flush
      @input.gets
    end

    def read_integer(label)
      raw = prompt(label)
      return nil if raw.nil?

      trimmed = raw.strip
      unless INTEGER_REGEX.match?(trimmed)
        raise ValidationError, "Очікувалося ціле число, отримано '#{trimmed}'"
      end

      Integer(trimmed, 10)
    end

    def show_all_records
      @output.puts "\n" + ReportFormatter.format_all_records(@analytics.records)
    end

    def show_student_averages
      avgs = @analytics.student_averages
      @output.puts "\n=== СЕРЕДНІЙ БАЛ СТУДЕНТІВ ==="
      avgs.sort_by { |name, _| name }.each do |name, info|
        @output.puts format("  %-15s : %6.2f (оцінок: %d)", name, info[:average], info[:count])
      end
    end

    def show_extrema_students
      avgs = @analytics.student_averages
      top = @analytics.top_students
      lowest = @analytics.lowest_students
      max_val = avgs.values.map { |v| v[:average] }.max
      min_val = avgs.values.map { |v| v[:average] }.min

      @output.puts "\n=== НАЙВИЩИЙ ТА НАЙНИЖЧИЙ СЕРЕДНІЙ БАЛ ==="
      @output.puts format("  Найвищий бал (%.2f): %s", max_val, top.join(", "))
      @output.puts format("  Найнижчий бал (%.2f): %s", min_val, lowest.join(", "))
    end

    def show_subject_averages
      avgs = @analytics.subject_averages
      @output.puts "\n=== СЕРЕДНІЙ БАЛ ЗА ПРЕДМЕТАМИ ==="
      avgs.sort_by { |subj, _| subj }.each do |subj, info|
        @output.puts format("  %-15s : %6.2f (оцінок: %d)", subj, info[:average], info[:count])
      end
    end

    def search_student
      query = prompt("Введіть ім'я студента: ")
      return if query.nil?

      matches = @analytics.find_student(query)
      @output.puts "\n" + ReportFormatter.format_student_search(query.strip, matches)
    rescue ValidationError => e
      @output.puts "Помилка пошуку: #{e.message}"
    end

    def add_grade_flow
      name = prompt("Ім'я студента: ")&.strip
      subject = prompt("Предмет: ")&.strip
      grade = read_integer("Оцінка (0..100): ")
      return if name.nil? || subject.nil? || grade.nil?

      record = @analytics.add_grade(name: name, subject: subject, grade: grade)
      @repository.save_records(@analytics.records)
      @output.puts "Додано та збережено: #{record.name} | #{record.subject} | #{record.grade}"
    rescue ValidationError, FileAccessError => e
      @output.puts "Помилка додавання: #{e.message}"
    end

    def edit_grade_flow
      show_all_records
      num = read_integer("Введіть номер запису для редагування: ")
      return if num.nil?

      new_grade = read_integer("Нова оцінка (0..100): ")
      return if new_grade.nil?

      updated = @analytics.update_grade(num - 1, new_grade: new_grade)
      @repository.save_records(@analytics.records)
      @output.puts "Оновлено та збережено запис ##{num}: #{updated.name} | #{updated.subject} | #{updated.grade}"
    rescue ValidationError, NotFoundError, FileAccessError => e
      @output.puts "Помилка редагування: #{e.message}"
    end

    def delete_grade_flow
      show_all_records
      num = read_integer("Введіть номер запису для видалення: ")
      return if num.nil?

      deleted = @analytics.delete_grade(num - 1)
      @repository.save_records(@analytics.records)
      @output.puts "Видалено та збережено: #{deleted.name} | #{deleted.subject} | #{deleted.grade}"
    rescue ValidationError, NotFoundError, FileAccessError => e
      @output.puts "Помилка видалення: #{e.message}"
    end

    def save_report_flow
      content = ReportFormatter.build_statistical_report(@analytics)
      File.write(@report_path, content, encoding: "UTF-8")
      @output.puts "Статистичний звіт збережено у файл: #{@report_path}"
    rescue Errno::EACCES, SystemCallError => e
      @output.puts "Помилка запису звіту у файл: #{e.message}"
    end
  end
end