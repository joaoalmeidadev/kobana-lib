require_relative 'base_error'

module Kobana
  module Errors
    class UnauthorizedError < BaseError
      def initialize
        super('Unauthorized request. Check your API key or permissions.', code: 401)
      end
    end
  end
end