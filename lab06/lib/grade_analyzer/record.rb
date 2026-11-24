# frozen_string_literal: true

module GradeAnalyzer
  class Record
    MIN_GRADE = 0
    MAX_GRADE = 100

    attr_reader :name, :subject, :grade

    def initialize(name:, subject:, grade:)
      @name = validate_non_empty_string(name, field: "name")
      @subject = validate_non_empty_string(subject, field: "subject")
      @grade = validate_grade(grade)
      freeze
    end

    def to_h
      { name: name, subject: subject, grade: grade }
    end

    private

    def validate_non_empty_string(value, field:)
      raise ValidationError, "Поле '#{field}' має бути рядком" unless value.is_a?(String)

      cleaned = value.strip
      raise ValidationError, "Поле '#{field}' не може бути порожнім" if cleaned.empty?

      cleaned
    end

    def validate_grade(value)
      unless value.is_a?(Integer) && !value.is_a?(FalseClass) && !value.is_a?(TrueClass)
        raise ValidationError, "Оцінка має бути цілим числом (отримано #{value.class})"
      end

      unless value.between?(MIN_GRADE, MAX_GRADE)
        raise ValidationError, "Оцінка #{value} виходить за межі #{MIN_GRADE}..#{MAX_GRADE}"
      end

      value
    end
  end
end