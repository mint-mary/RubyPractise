# frozen_string_literal: true

module GradeAnalyzer
  class Error < StandardError; end
  class FileAccessError < Error; end
  class DataFormatError < Error; end
  class ValidationError < Error; end
  class NotFoundError < Error; end
end