require 'bundler/setup'  
Bundler.require(:default)

require 'date'
require 'json'

require_relative 'kobana/version'
require_relative 'kobana/errors/base_error'
require_relative 'kobana/errors/api_error'
require_relative 'kobana/errors/validation_error'
require_relative 'kobana/errors/unauthorized_error'
require_relative 'kobana/validators/helpers'
require_relative 'kobana/validators/charge_pix_validator'
require_relative 'kobana/translators/charge_pix_translator'
require_relative 'kobana/translators/create_pix_account_translator'
require_relative 'kobana/base'
require_relative 'kobana/charge_pix_service'
require_relative 'kobana/create_pix_account_service'

module Kobana
  class Error < StandardError; end
  
  class << self
    attr_accessor :api_key, :environment
    
    def configure
      yield self if block_given?
    end
    
    def api_key
      @api_key ||= ENV['KOBANA_API_KEY']
    end
    
    def environment
      @environment ||= ENV['KOBANA_ENV'] || 'development'
    end
    
    def base_uri
      environment == 'production' ? 
        'https://api.kobana.com.br' : 
        'https://api-sandbox.kobana.com.br'
    end
  end
end