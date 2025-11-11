# lib/kobana/validators/helpers.rb
module Kobana
  module Validators
    module Helpers
      UUID_REGEX = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

      BRAZILIAN_STATES = %w[
        AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI 
        RJ RN RS RO RR SC SP SE TO
      ].freeze

      def valid_uuid?(uuid)
        return false if uuid.nil?
        uuid.to_s.match?(UUID_REGEX)
      end

      def valid_cep?(cep)
        return false if cep.nil?
      
        clean_cep = cep.to_s.gsub(/\D/, '')
        clean_cep.length == 8 && clean_cep.match?(/^\d{8}$/)
      end

      def valid_brazilian_state?(state)
        return false if state.nil?
        BRAZILIAN_STATES.include?(state.to_s.upcase)
      end
    end
  end
end