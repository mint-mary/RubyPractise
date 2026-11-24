# frozen_string_literal: true

module GradeAnalyzer
  class Analytics
    attr_reader :records

    def initialize(records = [])
      @records = records.dup
    end

    def replace_records(new_records)
      @records = new_records.dup
    end

    def student_averages
      grouped = @records.group_by(&:name)
      grouped.transform_values do |list|
        avg = list.sum(&:grade).to_f / list.size
        {
          average: avg.round(2),
          count: list.size,
          grades: list.map { |r| { subject: r.subject, grade: r.grade } }
        }
      end
    end

    def subject_averages
      grouped = @records.group_by(&:subject)
      grouped.transform_values do |list|
        avg = list.sum(&:grade).to_f / list.size
        {
          average: avg.round(2),
          count: list.size
        }
      end
    end

    def top_students
      averages = student_averages
      return [] if averages.empty?

      max_avg = averages.values.map { |v| v[:average] }.max
      averages.select { |_, v| v[:average] == max_avg }.keys.sort
    end

    def lowest_students
      averages = student_averages
      return [] if averages.empty?

      min_avg = averages.values.map { |v| v[:average] }.min
      averages.select { |_, v| v[:average] == min_avg }.keys.sort
    end

    def find_student(query_name)
      raise ValidationError, "Ім'я для пошуку не може бути порожнім" if query_name.to_s.strip.empty?

      needle = query_name.strip.downcase
      matches = @records.select { |r| r.name.downcase == needle }
      return matches unless matches.empty?

      # Частковий пошук за підрядком, якщо точного збігу немає
      @records.select { |r| r.name.downcase.include?(needle) }
    end

    def add_grade(name:, subject:, grade:)
      record = Record.new(name: name, subject: subject, grade: grade)
      @records << record
      record
    end

    def update_grade(index, new_grade:)
      validate_index!(index)
      current = @records[index]
      updated = Record.new(name: current.name, subject: current.subject, grade: new_grade)
      @records[index] = updated
      updated
    end

    def delete_grade(index)
      validate_index!(index)
      @records.delete_at(index)
    end

    private

    def validate_index!(index)
      unless index.is_a?(Integer) && index.between?(0, @records.length - 1)
        raise NotFoundError, "Запис з індексом #{index} не знайдено"
      end
    end
  end
end