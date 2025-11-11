
module Kobana
  module Translators
    class ChargePixTranslator
      def initialize(data)
        @data = data
      end

      def call
        {
          amount: @data.dig(:amount),
          payer: payer_params,
          pix_account_uid: @data.dig(:pix_account_uid),
          external_id: @data.dig(:external_id),
          fine_type: @data.dig(:fine_type),
          fine_amount: @data.dig(:fine_amount),
          txid: @data.dig(:txid),
          expire_at: @data.dig(:expire_at),
          revoke_days: @data.dig(:revoke_days),
          message: @data.dig(:message),
          additional_info: @data.dig(:additional_info),
          registration_kind: @data.dig(:registration_kind) || 'instant',
          custom_data: @data.dig(:custom_data),
          external_id: @data.dig(:external_id),
          fine_percentage: @data.dig(:fine_percentage),
          reduction_type: @data.dig(:reduction_type) || 0,
          reduction_amount: @data.dig(:reduction_amount),
          reduction_percentage: @data.dig(:reduction_percentage),
          interest_type: @data.dig(:interest_type) || 0,
          interest_amount: @data.dig(:interest_amount),
          interest_percentage: @data.dig(:interest_percentage),
          tags: @data.dig(:tags)
        }.compact
      end

      private

      def payer_params
        return nil unless @data.dig(:payer)

        {
          document_number: @data.dig(:payer, :document_number),
          name: @data.dig(:payer, :name),
          email: @data.dig(:payer, :email),
          address: address_params
        }.compact
      end

      def address_params
        return nil unless @data.dig(:payer, :address)

        {
          street: @data.dig(:payer, :address, :street),
          zip_code: @data.dig(:payer, :address, :zip_code),
          complement: @data.dig(:payer, :address, :complement),
          number: @data.dig(:payer, :address, :number),
          neighborhood: @data.dig(:payer, :address, :neighborhood),
          city_name: @data.dig(:payer, :address, :city_name),
          state: @data.dig(:payer, :address, :state)
        }.compact
      end
    end
  end
end