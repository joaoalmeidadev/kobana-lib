require_relative '../errors/validation_error'
require 'cpf_cnpj'

module Kobana
  module Validators
    class ChargePixValidator
      include Kobana::Validators::Helpers
      attr_reader :errors

      def initialize(data)
        @data = data
        @errors = []
      end

      def valid?
        @errors = []
        
        validate_required_fields
        validate_amount
        validate_payer
        validate_pix_account_uid
        validate_expire_at
        validate_registration_kind
        validate_fine_fields
        validate_reduction_fields
        validate_interest_fields
        validate_tags
        
        @errors.empty?
      end

      def call
        unless valid?
          raise Kobana::Errors::ValidationError, @errors
        end
        true
      end

      def error_messages
        @errors.join(', ')
      end

      private

      def validate_required_fields
        add_error('amount is required') if @data.dig(:amount).nil?
        add_error('payer is required') if @data.dig(:payer).nil?
        add_error('pix_account_uid is required') if @data.dig(:pix_account_uid).nil?
        add_error('expire_at is required') if @data.dig(:expire_at).nil?
        add_error('external_id is required') if @data.dig(:external_id).nil?
      end

      def validate_amount
        amount = @data.dig(:amount)
        return if amount.nil?

        unless amount.is_a?(Numeric)
          add_error('amount must be a number')
          return
        end

        add_error('amount must be greater than or equal to 0.01') if amount < 0.01
      end

      def validate_payer
        payer = @data.dig(:payer)
        return if payer.nil?

        validate_payer_required_fields(payer)
        validate_document_number(payer[:document_number])
        validate_email(payer[:email]) if payer[:email]
        validate_address(payer[:address]) if payer[:address]
      end

      def validate_payer_required_fields(payer)
        add_error('payer.document_number is required') if payer[:document_number].nil? || payer[:document_number].to_s.empty?
        add_error('payer.name is required') if payer[:name].nil? || payer[:name].to_s.empty?
      end

      def validate_document_number(document)
        return if ::CPF.valid?(document) || ::CNPJ.valid?(document)

        add_error('payer.document_number must be a valid CPF (11 digits) or CNPJ (14 digits)')
      end

      def validate_email(email)
        return if email.nil?

        unless ::ValidEmail2::Address.new(email).valid?
          add_error('payer.email must be a valid email address')
        end
      end

      def validate_address(address)
        return if address.nil?

        if @data.dig(:registration_kind) == 'billing'
          required_address_fields = [:street, :zip_code, :number, :neighborhood, :city_name, :state]
          
          required_address_fields.each do |field|
            if address[field].nil? || address[field].to_s.empty?
              add_error("payer.address.#{field} is required for billing registration_kind")
            end
          end
        end

        validate_zip_code(address[:zip_code]) if address[:zip_code]
        validate_state(address[:state]) if address[:state]
      end

      def validate_zip_code(zip_code)
        return if valid_cep?(zip_code)
      
        add_error('payer.address.zip_code must be a valid Brazilian ZIP code (8 digits)')
      end

      def validate_state(state)
        return if valid_brazilian_state?(state)
      
        add_error('payer.address.state must be a valid Brazilian state code')
      end

      def validate_pix_account_uid
        uid = @data.dig(:pix_account_uid)
      
        if uid.nil? || uid.to_s.strip.empty?
          add_error('pix_account_uid is required')
          return
        end
      
        add_error('pix_account_uid must be a valid UUID') unless valid_uuid?(uid)
      end

      def validate_expire_at
        expire_at = @data.dig(:expire_at)
      
        if expire_at.nil? || expire_at.to_s.strip.empty?
          add_error('expire_at is required')
          return
        end
      
        begin
          DateTime.iso8601(expire_at.to_s)
        rescue ArgumentError
          add_error('expire_at must be in ISO8601 format (e.g., 2024-12-31T23:59:59Z)')
        end
      end

      def validate_registration_kind
        kind = @data.dig(:registration_kind)
        return if kind.nil?

        valid_kinds = %w[instant billing]
        add_error("registration_kind must be one of: #{valid_kinds.join(', ')}") unless valid_kinds.include?(kind.to_s)
      end

      def validate_fine_fields
        fine_type = @data.dig(:fine_type)
        return if fine_type.nil? || fine_type == 0

        unless [0, 1, 2].include?(fine_type)
          add_error('fine_type must be 0 (none), 1 (value), or 2 (percentage)')
          return
        end

        case fine_type
        when 1
          validate_fine_amount
        when 2
          validate_fine_percentage
        end
      end

      def validate_fine_amount
        amount = @data.dig(:fine_amount)
        if amount.nil? || amount.to_s.empty?
          add_error('fine_amount is required when fine_type is 1')
        elsif amount.to_f <= 0
          add_error('fine_amount must be greater than 0')
        end
      end

      def validate_fine_percentage
        percentage = @data.dig(:fine_percentage)
        if percentage.nil? || percentage.to_s.empty?
          add_error('fine_percentage is required when fine_type is 2')
        elsif percentage.to_f <= 0 || percentage.to_f > 100
          add_error('fine_percentage must be between 0 and 100')
        end
      end

      def validate_reduction_fields
        reduction_type = @data.dig(:reduction_type)
        return if reduction_type.nil? || reduction_type == 0

        unless [0, 1, 2].include?(reduction_type)
          add_error('reduction_type must be 0 (none), 1 (value), or 2 (percentage)')
          return
        end

        case reduction_type
        when 1
          validate_reduction_amount
        when 2
          validate_reduction_percentage
        end
      end

      def validate_reduction_amount
        amount = @data.dig(:reduction_amount)
        if amount.nil? || amount.to_s.empty?
          add_error('reduction_amount is required when reduction_type is 1')
        elsif amount.to_f <= 0
          add_error('reduction_amount must be greater than 0')
        end
      end

      def validate_reduction_percentage
        percentage = @data.dig(:reduction_percentage)
        if percentage.nil? || percentage.to_s.empty?
          add_error('reduction_percentage is required when reduction_type is 2')
        elsif percentage.to_f <= 0 || percentage.to_f > 100
          add_error('reduction_percentage must be between 0 and 100')
        end
      end

      def validate_interest_fields
        interest_type = @data.dig(:interest_type)
        return if interest_type.nil? || interest_type == 0

        unless [0, 1, 2, 3].include?(interest_type)
          add_error('interest_type must be 0 (none), 1 (daily value), 2 (daily percentage), or 3 (monthly percentage)')
          return
        end

        case interest_type
        when 1
          validate_interest_amount
        when 2, 3
          validate_interest_percentage
        end
      end

      def validate_interest_amount
        amount = @data.dig(:interest_amount)
        if amount.nil? || amount.to_s.empty?
          add_error('interest_amount is required when interest_type is 1')
        elsif amount.to_f <= 0
          add_error('interest_amount must be greater than 0')
        end
      end

      def validate_interest_percentage
        percentage = @data.dig(:interest_percentage)
        if percentage.nil? || percentage.to_s.empty?
          add_error('interest_percentage is required when interest_type is 2 or 3')
        elsif percentage.to_f <= 0 || percentage.to_f > 100
          add_error('interest_percentage must be between 0 and 100')
        end
      end

      def validate_tags
        tags = @data.dig(:tags)
        return if tags.nil?

        unless tags.is_a?(Array)
          add_error('tags must be an array')
          return
        end

        tags.each_with_index do |tag, index|
          add_error("tags[#{index}] must be a string") unless tag.is_a?(String)
        end
      end

      def add_error(message)
        @errors << message
      end
    end
  end
end