require 'spec_helper'

RSpec.describe Kobana::Validators::Helpers do
  let(:test_class) do
    Class.new do
      include Kobana::Validators::Helpers
    end
  end

  let(:helper) { test_class.new }

  describe '#valid_uuid?' do
    context 'with valid UUIDs' do
      it 'returns true for valid UUID v4' do
        expect(helper.valid_uuid?('550e8400-e29b-41d4-a716-446655440000')).to be true
      end

      it 'returns true for valid UUID with uppercase letters' do
        expect(helper.valid_uuid?('550E8400-E29B-41D4-A716-446655440000')).to be true
      end

      it 'returns true for valid UUID with mixed case' do
        expect(helper.valid_uuid?('550e8400-E29b-41d4-A716-446655440000')).to be true
      end
    end

    context 'with invalid UUIDs' do
      it 'returns false for nil' do
        expect(helper.valid_uuid?(nil)).to be false
      end

      it 'returns false for empty string' do
        expect(helper.valid_uuid?('')).to be false
      end

      it 'returns false for invalid format' do
        expect(helper.valid_uuid?('not-a-uuid')).to be false
      end

      it 'returns false for UUID with wrong length' do
        expect(helper.valid_uuid?('550e8400-e29b-41d4-a716')).to be false
      end

      it 'returns false for string without dashes' do
        expect(helper.valid_uuid?('550e8400e29b41d4a716446655440000')).to be false
      end

      it 'returns false for numeric value' do
        expect(helper.valid_uuid?(12345)).to be false
      end
    end
  end

  describe '#valid_cep?' do
    context 'with valid CEPs' do
      it 'returns true for CEP with 8 digits' do
        expect(helper.valid_cep?('12345678')).to be true
      end

      it 'returns true for CEP with formatting' do
        expect(helper.valid_cep?('12345-678')).to be true
      end

      it 'returns true for CEP with extra formatting' do
        expect(helper.valid_cep?('12.345-678')).to be true
      end

      it 'returns true for numeric CEP' do
        expect(helper.valid_cep?(12345678)).to be true
      end
    end

    context 'with invalid CEPs' do
      it 'returns false for nil' do
        expect(helper.valid_cep?(nil)).to be false
      end

      it 'returns false for empty string' do
        expect(helper.valid_cep?('')).to be false
      end

      it 'returns false for CEP with less than 8 digits' do
        expect(helper.valid_cep?('1234567')).to be false
      end

      it 'returns false for CEP with more than 8 digits' do
        expect(helper.valid_cep?('123456789')).to be false
      end

      it 'returns false for CEP with letters' do
        expect(helper.valid_cep?('1234567a')).to be false
      end

      it 'returns false for CEP with only non-digits after cleaning' do
        expect(helper.valid_cep?('abcdefgh')).to be false
      end
    end
  end

  describe '#valid_brazilian_state?' do
    context 'with valid state codes' do
      it 'returns true for SP' do
        expect(helper.valid_brazilian_state?('SP')).to be true
      end

      it 'returns true for RJ' do
        expect(helper.valid_brazilian_state?('RJ')).to be true
      end

      it 'returns true for lowercase state code' do
        expect(helper.valid_brazilian_state?('sp')).to be true
      end

      it 'returns true for all valid states' do
        states = %w[AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO]
        states.each do |state|
          expect(helper.valid_brazilian_state?(state)).to be true
        end
      end
    end

    context 'with invalid state codes' do
      it 'returns false for nil' do
        expect(helper.valid_brazilian_state?(nil)).to be false
      end

      it 'returns false for invalid state code' do
        expect(helper.valid_brazilian_state?('XX')).to be false
      end

      it 'returns false for empty string' do
        expect(helper.valid_brazilian_state?('')).to be false
      end

      it 'returns false for numeric value' do
        expect(helper.valid_brazilian_state?(12)).to be false
      end

      it 'returns false for state code with wrong length' do
        expect(helper.valid_brazilian_state?('SPA')).to be false
      end
    end
  end
end

