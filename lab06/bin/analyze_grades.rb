#!/usr/bin/env ruby
# frozen_string_literal: true

begin
  require "bundler/setup"
rescue LoadError
  # Дозволяємо запуск навіть без Bundler, якщо Gemfile не використовується
end

require_relative "../lib/grade_analyzer"

default_csv = File.expand_path("../data/grades.csv", __dir__)
default_report = File.expand_path("../report.txt", __dir__)

csv_path = ARGV[0] || default_csv
report_path = ARGV[1] || default_report

begin
  repository = GradeAnalyzer::Repository.new(csv_path)
  records = repository.load_records
  analytics = GradeAnalyzer::Analytics.new(records)
  cli = GradeAnalyzer::CLI.new(
    repository: repository,
    analytics: analytics,
    report_path: report_path
  )
  cli.run
rescue GradeAnalyzer::FileAccessError => e
  warn "Помилка файлу: #{e.message}"
  exit 3
rescue GradeAnalyzer::DataFormatError, GradeAnalyzer::ValidationError => e
  warn "Помилка даних: #{e.message}"
  exit 2
end