describe Spree::Gateway::AdyenCse do
  let(:psp_reference) { '53880' }
  let(:currency) { 'GBP' }
  let(:success) { true }

  let(:credit_card) { create(:credit_card) }
  let(:gateway) { create(:adyen_cse_payment_method, name: 'Adyen') }

  let(:additional_response_attr) do
    {}
  end

  let(:response_attr) do
    { success?: success, psp_reference: psp_reference }.merge(additional_response_attr)
  end

  let(:response) do
    double('Response', response_attr)
  end

  it { expect(subject.method_type).to eq('adyen_cse') }
  it { expect(subject.actions).to match_array(%w(credit void)) }

  context 'provider API calls' do
    before do
      expect(gateway.provider).to receive(method).and_return(response)
    end

    describe '#capture' do
      let(:method) { :capture_payment }

      subject { gateway.capture(10, psp_reference, currency: currency).authorization }

      include_examples 'a successful adyen response'
    end

    describe '#credit' do
      let(:method) { :cancel_or_refund_payment }

      subject { gateway.credit(10, credit_card, psp_reference, currency: currency).authorization }

      include_examples 'a successful adyen response'
    end

    describe '#void' do
      let(:method) { :cancel_payment }

      subject { gateway.void(psp_reference, credit_card).authorization }

      include_examples 'a successful adyen response'
    end

    context 'when it returns an error' do
      let(:success) { false }

      let(:additional_response_attr) do
        { result_code: 'T35T', refusal_reason: 'Only testing' }
      end

      describe '#capture' do
        let(:method) { :capture_payment }
        let(:expected_reponse_string) { 'T35T - Only testing' }

        subject { gateway.capture(10, psp_reference, currency: currency) }

        include_examples 'a failed adyen response'
      end

      describe '#credit' do
        let(:method) { :cancel_or_refund_payment }
        let(:expected_reponse_string) { 'Only testing' }

        subject { gateway.credit(10, credit_card, psp_reference, currency: currency) }

        include_examples 'a failed adyen response'
      end

      describe '#void' do
        let(:method) { :cancel_payment }
        let(:expected_reponse_string) { 'T35T - Only testing' }

        subject { gateway.void(psp_reference, credit_card) }

        include_examples 'a failed adyen response'
      end
    end
  end
end
