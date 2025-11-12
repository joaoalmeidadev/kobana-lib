require 'spec_helper'

RSpec.describe Kobana::ChargePixService do
  let(:api_key) { 'test-api-key' }
  let(:valid_uuid) { '550e8400-e29b-41d4-a716-446655440000' }
  let(:valid_data) do
    {
      amount: 100.50,
      payer: {
        document_number: '12345678909',
        name: 'John Doe',
        email: 'test@example.com'
      },
      pix_account_uid: valid_uuid,
      external_id: 'external-123',
      expire_at: '2024-12-31T23:59:59Z'
    }
  end

  let(:success_response) do
    double(
      'HTTParty::Response',
      code: 200,
      body: { 'id' => 1, 'status' => 'created' }.to_json
    )
  end

  before do
    Kobana.api_key = api_key
    allow(Kobana).to receive(:base_uri).and_return('https://api-sandbox.kobana.com.br')
  end

  describe '#initialize' do
    it 'raises error when API key is not provided' do
      Kobana.api_key = nil
      expect {
        described_class.new(data: valid_data, api_key: nil)
      }.to raise_error(ArgumentError, 'API key is required')
    end

    it 'accepts API key as parameter' do
      Kobana.api_key = nil
      service = described_class.new(data: valid_data, api_key: api_key)
      expect(service).to be_a(described_class)
    end

    it 'uses API key from configuration when not provided as parameter' do
      Kobana.api_key = api_key
      service = described_class.new(data: valid_data)
      expect(service).to be_a(described_class)
    end
  end

  describe '#call' do
    let(:service) { described_class.new(data: valid_data, api_key: api_key, which_endpoint: :charge_pix) }
    let(:translator) { instance_double(Kobana::Translators::ChargePixTranslator) }
    let(:validator) { instance_double(Kobana::Validators::ChargePixValidator) }
    let(:translated_data) { { amount: 100.50, payer: {} } }

    before do
      allow(service).to receive(:validator).and_return(validator)
      allow(service).to receive(:translator).and_return(translator)
      allow(validator).to receive(:call).and_return(true)
      allow(translator).to receive(:call).and_return(translated_data)
    end

    context 'with valid data' do
      it 'calls the validator' do
        allow(service.class).to receive(:post).and_return(success_response)
        expect(validator).to receive(:call)
        service.call
      end

      it 'calls the translator' do
        allow(service.class).to receive(:post).and_return(success_response)
        expect(translator).to receive(:call).and_return(translated_data)
        service.call
      end

      it 'makes HTTP request with correct endpoint' do
        allow(service.class).to receive(:post).and_return(success_response)
        expect(service.class).to receive(:post).with(
          '/v2/charge/pix',
          hash_including(
            headers: hash_including(
              'Authorization' => "Bearer #{api_key}",
              'Content-Type' => 'application/json'
            ),
            body: translated_data.to_json
          )
        )
        service.call
      end

      it 'returns the parsed response' do
        allow(service.class).to receive(:post).and_return(success_response)
        result = service.call
        expect(result).to eq({ 'id' => 1, 'status' => 'created' })
      end
    end

    context 'when validation fails' do
      it 'raises ValidationError and does not make HTTP request' do
        validation_error = Kobana::Errors::ValidationError.new(['amount is required'])
        allow(validator).to receive(:call).and_raise(validation_error)
        allow(service.class).to receive(:post)

        expect {
          service.call
        }.to raise_error(Kobana::Errors::ValidationError)

        expect(service.class).not_to have_received(:post)
      end
    end

    context 'when API returns validation error' do
      let(:validation_error_response) do
        double(
          'HTTParty::Response',
          code: 422,
          body: { 'errors' => ['Invalid amount'] }.to_json
        )
      end

      it 'raises ValidationError' do
        allow(service.class).to receive(:post).and_return(validation_error_response)
        expect {
          service.call
        }.to raise_error(Kobana::Errors::ValidationError) do |error|
          expect(error.errors).to include('Invalid amount')
        end
      end
    end

    context 'when API returns unauthorized error' do
      let(:unauthorized_response) do
        double(
          'HTTParty::Response',
          code: 401,
          body: { 'error' => 'Unauthorized' }.to_json
        )
      end

      it 'raises UnauthorizedError' do
        allow(service.class).to receive(:post).and_return(unauthorized_response)
        expect {
          service.call
        }.to raise_error(Kobana::Errors::UnauthorizedError)
      end
    end

    context 'when API returns other error' do
      let(:error_response) do
        response_body = { 'error' => 'Internal Server Error' }.to_json
        double(
          'HTTParty::Response',
          code: 500,
          body: response_body,
          message: 'Internal Server Error',
          parsed_response: JSON.parse(response_body)
        )
      end

      it 'raises ApiError' do
        allow(service.class).to receive(:post).and_return(error_response)
        expect {
          service.call
        }.to raise_error(Kobana::Errors::ApiError)
      end
    end

    context 'when JSON parsing fails' do
      let(:invalid_json_response) do
        double(
          'HTTParty::Response',
          code: 200,
          body: 'invalid json{'
        )
      end

      it 'returns empty hash when JSON is invalid' do
        allow(service.class).to receive(:post).and_return(invalid_json_response)
        result = service.call
        # parse_response_body returns {} when JSON parsing fails
        expect(result).to eq({})
      end
    end

    context 'when network error occurs' do
      it 'raises BaseError with network error message' do
        allow(service.class).to receive(:post).and_raise(SocketError.new('Connection refused'))
        
        expect {
          service.call
        }.to raise_error(Kobana::Errors::BaseError, /Network error/)
      end
    end
  end

  describe '#validator' do
    it 'returns ChargePixValidator instance' do
      service = described_class.new(data: valid_data, api_key: api_key)
      validator = service.send(:validator)
      expect(validator).to be_a(Kobana::Validators::ChargePixValidator)
    end

    it 'passes data to validator' do
      service = described_class.new(data: valid_data, api_key: api_key)
      validator = service.send(:validator)
      expect(validator.instance_variable_get(:@data)).to eq(valid_data)
    end
  end

  describe '#translator' do
    it 'returns ChargePixTranslator instance' do
      service = described_class.new(data: valid_data, api_key: api_key)
      translator = service.send(:translator)
      expect(translator).to be_a(Kobana::Translators::ChargePixTranslator)
    end

    it 'passes data to translator' do
      service = described_class.new(data: valid_data, api_key: api_key)
      translator = service.send(:translator)
      expect(translator.instance_variable_get(:@data)).to eq(valid_data)
    end
  end
end

