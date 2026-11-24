# frozen_string_literal: true

module GradeAnalyzer
  class ReportFormatter
    def self.format_all_records(records)
      return "Записів про оцінки немає." if records.empty?

      lines = ["=== УСІ ОЦІНКИ СТУДЕНТІВ ==="]
      records.each_with_index do |rec, i|
        lines << format("%2d. %-15s | %-15s | %3d", i + 1, rec.name, rec.subject, rec.grade)
      end
      lines.join("\n")
    end

    def self.format_student_search(query, matches)
      return "Студента за запитом '#{query}' не знайдено." if matches.empty?

      avg = (matches.sum(&:grade).to_f / matches.size).round(2)
      lines = ["=== РЕЗУЛЬТАТИ ПОШУКУ: '#{query}' (середній бал: #{format('%.2f', avg)}) ==="]
      matches.each do |rec|
        lines << "  - #{rec.name}: #{rec.subject} — #{rec.grade}"
      end
      lines.join("\n")
    end

    def self.build_statistical_report(analytics, generated_at: Time.now)
      records = analytics.records
      student_avgs = analytics.student_averages
      subject_avgs = analytics.subject_averages
      top = analytics.top_students
      lowest = analytics.lowest_students

      lines = []
      lines << "СТАТИСТИЧНИЙ ЗВІТ З УСПІШНОСТІ СТУДЕНТІВ"
      lines << "Дата формування: #{generated_at.strftime('%Y-%m-%d %H:%M:%S')}"
      lines << "Загальна кількість записів: #{records.size}"
      lines << "=" * 50
      lines << ""

      lines << "1. СЕРЕДНІЙ БАЛ ЗА КОЖНИМ СТУДЕНТОМ:"
      if student_avgs.empty?
        lines << "  Немає даних."
      else
        student_avgs.sort_by { |name, _| name }.each do |name, info|
          lines << format("  %-15s | Середній: %6.2f | Кількість оцінок: %d", name, info[:average], info[:count])
        end
      end
      lines << ""

      lines << "2. НАЙВИЩИЙ ТА НАЙНИЖЧИЙ СЕРЕДНІЙ БАЛ:"
      if student_avgs.empty?
        lines << "  Немає даних."
      else
        max_val = student_avgs.values.map { |v| v[:average] }.max
        min_val = student_avgs.values.map { |v| v[:average] }.min
        lines << format("  Найвищий середній бал (%.2f): %s", max_val, top.join(", "))
        lines << format("  Найнижчий середній бал (%.2f): %s", min_val, lowest.join(", "))
      end
      lines << ""

      lines << "3. СЕРЕДНІЙ БАЛ ЗА КОЖНИМ ПРЕДМЕТОМ:"
      if subject_avgs.empty?
        lines << "  Немає даних."
      else
        subject_avgs.sort_by { |subj, _| subj }.each do |subj, info|
          lines << format("  %-15s | Середній: %6.2f | Кількість оцінок: %d", subj, info[:average], info[:count])
        end
      end
      lines << ""

      lines << "4. ПОВНИЙ ПЕРЕЛІК ОЦІНОК:"
      records.each_with_index do |rec, idx|
        lines << format("  %2d. %-15s | %-15s | %3d", idx + 1, rec.name, rec.subject, rec.grade)
      end

      lines.join("\n")
    end
  end
end