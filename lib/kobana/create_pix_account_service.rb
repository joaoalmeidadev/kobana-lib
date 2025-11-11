require 'json'
require 'httparty'

module Kobana
  class CreatePixAccountService < Base
    def initialize(data: {}, api_key: nil, which_endpoint: nil)
      super(data: data, api_key: api_key, which_endpoint: which_endpoint)
    end

    def call
      body = translator.call
      make_request(body)
    end
  end
end
