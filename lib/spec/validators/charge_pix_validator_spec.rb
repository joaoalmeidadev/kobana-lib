require 'spec_helper'

RSpec.describe Kobana::Validators::ChargePixValidator do
  let(:valid_cpf) { '57345658570' }
  let(:valid_cnpj) { '85528357806099' }
  let(:valid_uuid) { '550e8400-e29b-41d4-a716-446655440000' }
  let(:valid_cep) { '12345678' }
  let(:valid_email) { 'test@example.com' }
  let(:valid_expire_at) { '2024-12-31T23:59:59Z' }

  let(:valid_data) do
    {
      amount: 100.50,
      payer: {
        document_number: valid_cpf,
        name: 'John Doe',
        email: valid_email
      },
      pix_account_uid: valid_uuid,
      external_id: 'external-123',
      expire_at: valid_expire_at
    }
  end

  describe '#valid?' do
    context 'with valid data' do
      it 'returns true' do
        validator = described_class.new(valid_data)
        expect(validator.valid?).to be true
      end

      it 'has no errors' do
        validator = described_class.new(valid_data)
        validator.valid?
        expect(validator.errors).to be_empty
      end

      context 'with CNPJ' do
        it 'returns true for valid CNPJ' do
          data = valid_data.merge(
            payer: valid_data[:payer].merge(document_number: valid_cnpj)
          )
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end
      end

      context 'with billing registration_kind and address' do
        it 'returns true when all address fields are present' do
          data = valid_data.merge(
            registration_kind: 'billing',
            payer: valid_data[:payer].merge(
              address: {
                street: 'Rua Teste',
                zip_code: valid_cep,
                number: '123',
                neighborhood: 'Centro',
                city_name: 'São Paulo',
                state: 'SP'
              }
            )
          )
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end
      end

      context 'with fine fields' do
        it 'returns true with fine_type 1 and fine_amount' do
          data = valid_data.merge(fine_type: 1, fine_amount: 10.0)
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end

        it 'returns true with fine_type 2 and fine_percentage' do
          data = valid_data.merge(fine_type: 2, fine_percentage: 5.0)
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end

        it 'returns true with fine_type 0' do
          data = valid_data.merge(fine_type: 0)
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end
      end

      context 'with reduction fields' do
        it 'returns true with reduction_type 1 and reduction_amount' do
          data = valid_data.merge(reduction_type: 1, reduction_amount: 10.0)
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end

        it 'returns true with reduction_type 2 and reduction_percentage' do
          data = valid_data.merge(reduction_type: 2, reduction_percentage: 5.0)
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end
      end

      context 'with interest fields' do
        it 'returns true with interest_type 1 and interest_amount' do
          data = valid_data.merge(interest_type: 1, interest_amount: 10.0)
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end

        it 'returns true with interest_type 2 and interest_percentage' do
          data = valid_data.merge(interest_type: 2, interest_percentage: 5.0)
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end

        it 'returns true with interest_type 3 and interest_percentage' do
          data = valid_data.merge(interest_type: 3, interest_percentage: 5.0)
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end
      end

      context 'with tags' do
        it 'returns true with array of strings' do
          data = valid_data.merge(tags: ['tag1', 'tag2'])
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end

        it 'returns true with empty array' do
          data = valid_data.merge(tags: [])
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end
      end
    end

    describe 'required fields validation' do
      it 'returns false when amount is missing' do
        data = valid_data.dup
        data.delete(:amount)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('amount is required')
      end

      it 'returns false when payer is missing' do
        data = valid_data.dup
        data.delete(:payer)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('payer is required')
      end

      it 'returns false when pix_account_uid is missing' do
        data = valid_data.dup
        data.delete(:pix_account_uid)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('pix_account_uid is required')
      end

      it 'returns false when expire_at is missing' do
        data = valid_data.dup
        data.delete(:expire_at)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('expire_at is required')
      end

      it 'returns false when external_id is missing' do
        data = valid_data.dup
        data.delete(:external_id)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('external_id is required')
      end
    end

    describe 'amount validation' do
      it 'returns false when amount is not a number' do
        data = valid_data.merge(amount: '100')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('amount must be a number')
      end

      it 'returns false when amount is less than 0.01' do
        data = valid_data.merge(amount: 0.001)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('amount must be greater than or equal to 0.01')
      end

      it 'returns false when amount is zero' do
        data = valid_data.merge(amount: 0)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('amount must be greater than or equal to 0.01')
      end

      it 'returns true when amount is exactly 0.01' do
        data = valid_data.merge(amount: 0.01)
        validator = described_class.new(data)
        expect(validator.valid?).to be true
      end
    end

    describe 'payer validation' do
      it 'returns false when document_number is missing' do
        data = valid_data.merge(
          payer: valid_data[:payer].dup.tap { |p| p.delete(:document_number) }
        )
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('payer.document_number is required')
      end

      it 'returns false when document_number is empty string' do
        data = valid_data.merge(
          payer: valid_data[:payer].merge(document_number: '')
        )
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('payer.document_number is required')
      end

      it 'returns false when name is missing' do
        data = valid_data.merge(
          payer: valid_data[:payer].dup.tap { |p| p.delete(:name) }
        )
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('payer.name is required')
      end

      it 'returns false when name is empty string' do
        data = valid_data.merge(
          payer: valid_data[:payer].merge(name: '')
        )
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('payer.name is required')
      end

      it 'returns false when document_number is invalid CPF/CNPJ' do
        data = valid_data.merge(
          payer: valid_data[:payer].merge(document_number: '12345678900')
        )
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('payer.document_number must be a valid CPF (11 digits) or CNPJ (14 digits)')
      end

      it 'returns false when email is invalid' do
        data = valid_data.merge(
          payer: valid_data[:payer].merge(email: 'invalid-email')
        )
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('payer.email must be a valid email address')
      end

      it 'returns true when email is valid' do
        data = valid_data.merge(
          payer: valid_data[:payer].merge(email: 'valid@example.com')
        )
        validator = described_class.new(data)
        expect(validator.valid?).to be true
      end

      it 'returns true when email is not provided' do
        data = valid_data.merge(
          payer: valid_data[:payer].dup.tap { |p| p.delete(:email) }
        )
        validator = described_class.new(data)
        expect(validator.valid?).to be true
      end
    end

    describe 'address validation' do
      context 'with billing registration_kind' do
        it 'returns false when street is missing' do
          data = valid_data.merge(
            registration_kind: 'billing',
            payer: valid_data[:payer].merge(
              address: {
                zip_code: valid_cep,
                number: '123',
                neighborhood: 'Centro',
                city_name: 'São Paulo',
                state: 'SP'
              }
            )
          )
          validator = described_class.new(data)
          expect(validator.valid?).to be false
          expect(validator.errors).to include('payer.address.street is required for billing registration_kind')
        end

        it 'returns false when zip_code is missing' do
          data = valid_data.merge(
            registration_kind: 'billing',
            payer: valid_data[:payer].merge(
              address: {
                street: 'Rua Teste',
                number: '123',
                neighborhood: 'Centro',
                city_name: 'São Paulo',
                state: 'SP'
              }
            )
          )
          validator = described_class.new(data)
          expect(validator.valid?).to be false
          expect(validator.errors).to include('payer.address.zip_code is required for billing registration_kind')
        end

        it 'returns false when zip_code is invalid' do
          data = valid_data.merge(
            registration_kind: 'billing',
            payer: valid_data[:payer].merge(
              address: {
                street: 'Rua Teste',
                zip_code: '123',
                number: '123',
                neighborhood: 'Centro',
                city_name: 'São Paulo',
                state: 'SP'
              }
            )
          )
          validator = described_class.new(data)
          expect(validator.valid?).to be false
          expect(validator.errors).to include('payer.address.zip_code must be a valid Brazilian ZIP code (8 digits)')
        end

        it 'returns false when state is invalid' do
          data = valid_data.merge(
            registration_kind: 'billing',
            payer: valid_data[:payer].merge(
              address: {
                street: 'Rua Teste',
                zip_code: valid_cep,
                number: '123',
                neighborhood: 'Centro',
                city_name: 'São Paulo',
                state: 'XX'
              }
            )
          )
          validator = described_class.new(data)
          expect(validator.valid?).to be false
          expect(validator.errors).to include('payer.address.state must be a valid Brazilian state code')
        end

        it 'returns true when state is valid but lowercase' do
          data = valid_data.merge(
            registration_kind: 'billing',
            payer: valid_data[:payer].merge(
              address: {
                street: 'Rua Teste',
                zip_code: valid_cep,
                number: '123',
                neighborhood: 'Centro',
                city_name: 'São Paulo',
                state: 'sp'
              }
            )
          )
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end
      end

      context 'with instant registration_kind' do
        it 'returns true when address is not provided' do
          data = valid_data.merge(registration_kind: 'instant')
          validator = described_class.new(data)
          expect(validator.valid?).to be true
        end
      end
    end

    describe 'pix_account_uid validation' do
      it 'returns false when pix_account_uid is empty string' do
        data = valid_data.merge(pix_account_uid: '')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('pix_account_uid is required')
      end

      it 'returns false when pix_account_uid is invalid UUID' do
        data = valid_data.merge(pix_account_uid: 'not-a-uuid')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('pix_account_uid must be a valid UUID')
      end

      it 'returns false when pix_account_uid is whitespace only' do
        data = valid_data.merge(pix_account_uid: '   ')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('pix_account_uid is required')
      end
    end

    describe 'expire_at validation' do
      it 'returns false when expire_at is empty string' do
        data = valid_data.merge(expire_at: '')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('expire_at is required')
      end

      it 'returns false when expire_at is invalid format' do
        data = valid_data.merge(expire_at: '2024/12/31')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('expire_at must be in ISO8601 format (e.g., 2024-12-31T23:59:59Z)')
      end

      it 'returns false when expire_at is not a valid date' do
        data = valid_data.merge(expire_at: 'invalid-date')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('expire_at must be in ISO8601 format (e.g., 2024-12-31T23:59:59Z)')
      end

      it 'returns true when expire_at is valid ISO8601 format' do
        data = valid_data.merge(expire_at: '2024-12-31T23:59:59+00:00')
        validator = described_class.new(data)
        expect(validator.valid?).to be true
      end
    end

    describe 'registration_kind validation' do
      it 'returns false when registration_kind is invalid' do
        data = valid_data.merge(registration_kind: 'invalid')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('registration_kind must be one of: instant, billing')
      end

      it 'returns true when registration_kind is instant' do
        data = valid_data.merge(registration_kind: 'instant')
        validator = described_class.new(data)
        expect(validator.valid?).to be true
      end

      it 'returns true when registration_kind is billing' do
        data = valid_data.merge(registration_kind: 'billing')
        validator = described_class.new(data)
        expect(validator.valid?).to be true
      end

      it 'returns true when registration_kind is nil' do
        data = valid_data.merge(registration_kind: nil)
        validator = described_class.new(data)
        expect(validator.valid?).to be true
      end
    end

    describe 'fine fields validation' do
      it 'returns false when fine_type is invalid' do
        data = valid_data.merge(fine_type: 3)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('fine_type must be 0 (none), 1 (value), or 2 (percentage)')
      end

      it 'returns false when fine_type is 1 and fine_amount is missing' do
        data = valid_data.merge(fine_type: 1)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('fine_amount is required when fine_type is 1')
      end

      it 'returns false when fine_type is 1 and fine_amount is zero' do
        data = valid_data.merge(fine_type: 1, fine_amount: 0)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('fine_amount must be greater than 0')
      end

      it 'returns false when fine_type is 2 and fine_percentage is missing' do
        data = valid_data.merge(fine_type: 2)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('fine_percentage is required when fine_type is 2')
      end

      it 'returns false when fine_type is 2 and fine_percentage is greater than 100' do
        data = valid_data.merge(fine_type: 2, fine_percentage: 101)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('fine_percentage must be between 0 and 100')
      end

      it 'returns false when fine_type is 2 and fine_percentage is zero' do
        data = valid_data.merge(fine_type: 2, fine_percentage: 0)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('fine_percentage must be between 0 and 100')
      end
    end

    describe 'reduction fields validation' do
      it 'returns false when reduction_type is invalid' do
        data = valid_data.merge(reduction_type: 3)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('reduction_type must be 0 (none), 1 (value), or 2 (percentage)')
      end

      it 'returns false when reduction_type is 1 and reduction_amount is missing' do
        data = valid_data.merge(reduction_type: 1)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('reduction_amount is required when reduction_type is 1')
      end

      it 'returns false when reduction_type is 2 and reduction_percentage is missing' do
        data = valid_data.merge(reduction_type: 2)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('reduction_percentage is required when reduction_type is 2')
      end

      it 'returns false when reduction_type is 2 and reduction_percentage is greater than 100' do
        data = valid_data.merge(reduction_type: 2, reduction_percentage: 101)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('reduction_percentage must be between 0 and 100')
      end
    end

    describe 'interest fields validation' do
      it 'returns false when interest_type is invalid' do
        data = valid_data.merge(interest_type: 4)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('interest_type must be 0 (none), 1 (daily value), 2 (daily percentage), or 3 (monthly percentage)')
      end

      it 'returns false when interest_type is 1 and interest_amount is missing' do
        data = valid_data.merge(interest_type: 1)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('interest_amount is required when interest_type is 1')
      end

      it 'returns false when interest_type is 2 and interest_percentage is missing' do
        data = valid_data.merge(interest_type: 2)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('interest_percentage is required when interest_type is 2 or 3')
      end

      it 'returns false when interest_type is 3 and interest_percentage is missing' do
        data = valid_data.merge(interest_type: 3)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('interest_percentage is required when interest_type is 2 or 3')
      end

      it 'returns false when interest_percentage is greater than 100' do
        data = valid_data.merge(interest_type: 2, interest_percentage: 101)
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('interest_percentage must be between 0 and 100')
      end
    end

    describe 'tags validation' do
      it 'returns false when tags is not an array' do
        data = valid_data.merge(tags: 'not-an-array')
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('tags must be an array')
      end

      it 'returns false when tags contains non-string elements' do
        data = valid_data.merge(tags: ['tag1', 123, 'tag2'])
        validator = described_class.new(data)
        expect(validator.valid?).to be false
        expect(validator.errors).to include('tags[1] must be a string')
      end

      it 'returns true when tags is nil' do
        data = valid_data.merge(tags: nil)
        validator = described_class.new(data)
        expect(validator.valid?).to be true
      end
    end
  end

  describe '#call' do
    context 'with valid data' do
      it 'returns true' do
        validator = described_class.new(valid_data)
        expect(validator.call).to be true
      end

      it 'does not raise an error' do
        validator = described_class.new(valid_data)
        expect { validator.call }.not_to raise_error
      end
    end

    context 'with invalid data' do
      it 'raises ValidationError' do
        data = valid_data.dup
        data.delete(:amount)
        validator = described_class.new(data)
        expect { validator.call }.to raise_error(Kobana::Errors::ValidationError)
      end

      it 'includes error messages in the exception' do
        data = valid_data.dup
        data.delete(:amount)
        data.delete(:payer)
        validator = described_class.new(data)
        expect { validator.call }.to raise_error(Kobana::Errors::ValidationError) do |error|
          expect(error.errors).to include('amount is required')
          expect(error.errors).to include('payer is required')
        end
      end
    end
  end

  describe '#error_messages' do
    it 'returns comma-separated error messages' do
      data = valid_data.dup
      data.delete(:amount)
      data.delete(:payer)
      validator = described_class.new(data)
      validator.valid?
      expect(validator.error_messages).to include('amount is required')
      expect(validator.error_messages).to include('payer is required')
    end
  end
end

