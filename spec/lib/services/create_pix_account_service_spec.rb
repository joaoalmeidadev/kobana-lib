require 'spec_helper'

RSpec.describe Kobana::CreatePixAccountService do
  let(:api_key) { 'test-api-key' }
  let(:valid_data) do
    {
      custom_name: 'Conta Principal',
      provider_slug: 'example_bank',
      key: 'keyexample@email.com',
      enabled: true,
      default: true
    }
  end

  let(:success_response) do
    double(
      'HTTParty::Response',
      code: 200,
      body: { 'id' => 1, 'key' => 'keyexample@email.com' }.to_json
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
    let(:service) { described_class.new(data: valid_data, api_key: api_key, which_endpoint: :create_pix_account) }
    let(:translator) { instance_double(Kobana::Translators::CreatePixAccountTranslator) }
    let(:translated_data) { { custom_name: 'Conta Principal', key: 'keyexample@email.com' } }

    before do
      allow(service).to receive(:translator).and_return(translator)
      allow(translator).to receive(:call).and_return(translated_data)
    end

    context 'with valid data' do
      it 'calls the translator' do
        allow(service.class).to receive(:post).and_return(success_response)
        expect(translator).to receive(:call).and_return(translated_data)
        service.call
      end

      it 'makes HTTP request with correct endpoint' do
        allow(service.class).to receive(:post).and_return(success_response)
        expect(service.class).to receive(:post).with(
          '/v2/charge/pix_accounts',
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
        expect(result).to eq({ 'id' => 1, 'key' => 'keyexample@email.com' })
      end
    end

    context 'when API returns validation error' do
      let(:validation_error_response) do
        double(
          'HTTParty::Response',
          code: 422,
          body: { 'errors' => ['Invalid key'] }.to_json
        )
      end

      it 'raises ValidationError' do
        allow(service.class).to receive(:post).and_return(validation_error_response)
        expect {
          service.call
        }.to raise_error(Kobana::Errors::ValidationError) do |error|
          expect(error.errors).to include('Invalid key')
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

  describe '#translator' do
    it 'returns CreatePixAccountTranslator instance' do
      service = described_class.new(data: valid_data, api_key: api_key)
      translator = service.send(:translator)
      expect(translator).to be_a(Kobana::Translators::CreatePixAccountTranslator)
    end

    it 'passes data to translator' do
      service = described_class.new(data: valid_data, api_key: api_key)
      translator = service.send(:translator)
      expect(translator.instance_variable_get(:@data)).to eq(valid_data)
    end
  end

  context 'with minimal data' do
    let(:minimal_data) { {} }

    it 'uses default values from translator' do
      service = described_class.new(data: minimal_data, api_key: api_key, which_endpoint: :create_pix_account)
      translator = service.send(:translator)
      translated = translator.call
      
      expect(translated[:custom_name]).to eq('Conta principal')
      expect(translated[:financial_provider_slug]).to eq('example_bank')
      expect(translated[:key]).to eq('keyexample@email.com')
      expect(translated[:enabled]).to be true
      expect(translated[:default]).to be true
    end
  end
end

