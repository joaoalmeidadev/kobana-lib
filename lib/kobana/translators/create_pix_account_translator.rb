
module Kobana
  module Translators
    class CreatePixAccountTranslator
      def initialize(data)
        @data = data
      end

      def call
        {
          custom_name: @data.dig(:custom_name) || "Conta principal",
          financial_provider_slug: @data.dig(:provider_slug) || "example_bank",
          key: @data.dig(:key) || "keyexample@email.com",
          enabled: @data.dig(:enabled) || true,
          default: @data.dig(:default) || true
        }
      end
    end
  end
end