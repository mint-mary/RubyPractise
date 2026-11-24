# frozen_string_literal: true

require "csv"

module GradeAnalyzer
  class Repository
    HEADERS = %w[name subject grade].freeze
    INTEGER_STRING_PATTERN = /\A-?\d+\z/.freeze

    attr_reader :file_path

    def initialize(file_path)
      @file_path = File.expand_path(file_path)
    end

    def load_records
      unless File.exist?(file_path)
        raise FileAccessError, "CSV-файл не знайдено: #{file_path}"
      end

      unless File.readable?(file_path)
        raise FileAccessError, "Немає прав на читання файлу: #{file_path}"
      end

      raw_content = File.read(file_path, encoding: "UTF-8")
      if raw_content.strip.empty?
        raise DataFormatError, "CSV-файл порожній: #{file_path}"
      end

      rows = CSV.parse(raw_content, headers: true, skip_blanks: true)
      validate_headers!(rows.headers)

      records = []
      rows.each_with_index do |row, idx|
        line_number = idx + 2 # +1 заголовок, +1 для 1-based нумерації
        records << parse_row(row, line_number)
      end

      if records.empty?
        raise DataFormatError, "CSV-файл містить лише заголовок і не має записів: #{file_path}"
      end

      records
    rescue Errno::ENOENT, Errno::EACCES => e
      raise FileAccessError, "Помилка файлової системи під час читання: #{e.message}"
    rescue CSV::MalformedCSVError => e
      raise DataFormatError, "Пошкоджений формат CSV: #{e.message}"
    end

    def save_records(records)
      records.each do |rec|
        raise ValidationError, "Очікувався GradeAnalyzer::Record" unless rec.is_a?(Record)
      end

      dir = File.dirname(file_path)
      FileUtils_mkdir_p_safe(dir)

      temp_path = "#{file_path}.tmp.#{Process.pid}"
      CSV.open(temp_path, "w", write_headers: true, headers: HEADERS, encoding: "UTF-8") do |csv|
        records.each do |rec|
          csv << [rec.name, rec.subject, rec.grade]
        end
      end

      File.rename(temp_path, file_path)
      true
    rescue Errno::EACCES, Errno::ENOSPC, Errno::EROFS => e
      File.delete(temp_path) if temp_path && File.exist?(temp_path)
      raise FileAccessError, "Не вдалося зберегти CSV-файл: #{e.message}"
    end

    private

    def FileUtils_mkdir_p_safe(dir)
      return if Dir.exist?(dir)

      # Створюємо директорії без зовнішніх залежностей
      parts = []
      current = dir
      until Dir.exist?(current)
        parts.unshift(current)
        parent = File.dirname(current)
        break if parent == current

        current = parent
      end
      parts.each { |p| Dir.mkdir(p) }
    rescue Errno::EACCES, SystemCallError => e
      raise FileAccessError, "Не вдалося створити каталог '#{dir}': #{e.message}"
    end

    def validate_headers!(headers)
      normalized = (headers || []).map { |h| h&.strip }
      unless normalized == HEADERS
        raise DataFormatError, "Некоректні заголовки CSV: #{normalized.inspect} (очікується #{HEADERS.inspect})"
      end
    end

    def parse_row(row, line_number)
      raw_name = row["name"]
      raw_subject = row["subject"]
      raw_grade = row["grade"]

      if raw_name.nil? || raw_subject.nil? || raw_grade.nil?
        raise DataFormatError, "Рядок #{line_number}: відсутні обов'язкові стовпці"
      end

      grade_str = raw_grade.to_s.strip
      unless INTEGER_STRING_PATTERN.match?(grade_str)
        raise DataFormatError, "Рядок #{line_number}: оцінка '#{raw_grade}' не є цілим числом"
      end

      Record.new(
        name: raw_name.to_s,
        subject: raw_subject.to_s,
        grade: Integer(grade_str, 10)
      )
    rescue ValidationError => e
      raise DataFormatError, "Рядок #{line_number}: #{e.message}"
    end
  end
end