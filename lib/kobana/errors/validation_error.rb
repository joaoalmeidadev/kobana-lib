require_relative 'base_error'

module Kobana
  module Errors
    class ValidationError < BaseError
      attr_reader :errors

      def initialize(errors)
        @errors = Array(errors)
        message = "Validation failed: #{@errors.join(', ')}"
        super(message, code: 422, details: errors)
      end
    end
  end
end