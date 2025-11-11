module Kobana
  module Errors
    class BaseError < StandardError
      attr_reader :code, :details

      def initialize(message = nil, code: nil, details: nil)
        @code = code
        @details = details
        super(message || 'An unexpected error occurred')
      end
    end
  end
end