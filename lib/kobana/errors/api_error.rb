require_relative 'base_error'

module Kobana
  module Errors
    class ApiError < BaseError
      attr_reader :response

      def initialize(response)
        @response = response
        message = parse_message(response)
        code = response.code rescue nil
        super(message, code: code, details: response.parsed_response)
      end

      private

      def parse_message(response)
        body = response.parsed_response rescue {}
        body['error'] || body['message'] || "Unexpected API error"
      end
    end
  end
end