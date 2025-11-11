require 'json'
require 'httparty'

module Kobana
  class Base
    include HTTParty

    def initialize(data: {}, api_key: nil, which_endpoint: nil)
      @data = data
      @api_key = Kobana.api_key || api_key
      @which_endpoint = which_endpoint
      
      raise ArgumentError, 'API key is required' if @api_key.nil? || @api_key.empty?

      self.class.base_uri(Kobana.base_uri)
    end

    def make_request(body)
      response = self.class.post(set_endpoint, {
        headers: request_headers,
        body: body.to_json
      })
    
      handle_response(response)
    rescue JSON::ParserError => e
      raise Kobana::Errors::BaseError.new("Invalid JSON response: #{e.message}", code: 500)
    rescue HTTParty::Error, SocketError => e
      raise Kobana::Errors::BaseError.new("Network error: #{e.message}", code: 500)
    end

    def translator
      base_name = self.class.name.split('::').last.sub('Service', '')
      translator_class_name = "Kobana::Translators::#{base_name}Translator"
    
      translator_class = Object.const_get(translator_class_name)
      translator_class.new(@data)
    rescue NameError => e
      raise "Translator not found: #{translator_class_name}. Error: #{e.message}"
    end    

    def validator
      base_name = self.class.name.split('::').last.sub('Service', '')
      validator_class_name = "Kobana::Validators::#{base_name}Validator"
    
      validator_class = Object.const_get(validator_class_name)
      validator_class.new(@data)
    rescue NameError => e
      raise "Validator not found: #{validator_class_name}. Error: #{e.message}"
    end

    private

    def request_headers
      {
        'Authorization' => "Bearer #{@api_key}".strip,
        'Content-Type' => 'application/json'
      }
    end

    def set_endpoint
      case @which_endpoint
      when :charge_pix 
        '/v2/charge/pix'
      when :create_pix_account
        '/v2/charge/pix_accounts'
      else 
        raise ArgumentError, "Invalid endpoint: #{@which_endpoint}"
      end
    end
    
    def handle_response(response)
      body = parse_response_body(response)
    
      case response.code
      when 200..299
        body
      when 400, 422
        error_message = body['errors'] || body['message'] || body['error'] || 'Validation error'
        raise Kobana::Errors::ValidationError.new(error_message)
      when 401
        raise Kobana::Errors::UnauthorizedError
      else
        error_message = body['message'] || body['error'] || "HTTP #{response.code}: #{response.message}"
        raise Kobana::Errors::ApiError.new(response)
      end
    end
    
    def parse_response_body(response)
      JSON.parse(response.body)
    rescue JSON::ParserError
      {}
    end
  end
end