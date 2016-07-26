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

  let(:active_merchant_response) do
    ActiveMerchant::Billing::Response.new(
      response.success,
      message(response),
      {},
      authorization: response.psp_reference
    )
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
      let(:method) { :refund_payment }

      subject { gateway.credit(10, psp_reference, currency: currency).authorization }

      include_examples 'a successful adyen response'
    end

    describe '#void' do
      let(:method) { :cancel_or_refund_payment }

      subject { gateway.void(psp_reference, credit_card).authorization }

      include_examples 'a successful adyen response'
    end

    context 'when it returns an error' do
      let(:success) { false }

      let(:additional_response_attr) do
        { result_code: 'T35T', refusal_reason: 'Refused' }
      end

      describe '#capture' do
        let(:method) { :capture_payment }
        let(:expected_reponse_string) { 'Payment unsuccessful' }

        subject { gateway.capture(10, psp_reference, currency: currency) }

        include_examples 'a failed adyen response'
      end

      describe '#credit' do
        let(:method) { :refund_payment }
        let(:expected_reponse_string) { 'Payment unsuccessful' }

        subject { gateway.credit(10, psp_reference, currency: currency) }

        include_examples 'a failed adyen response'
      end

      describe '#void' do
        let(:method) { :cancel_or_refund_payment }
        let(:expected_reponse_string) { 'Payment unsuccessful' }

        subject { gateway.void(psp_reference, credit_card) }

        include_examples 'a failed adyen response'
      end

      context 'when in another locale' do
        around(:example) do |example|
          original_locale = I18n.locale

          I18n.locale = :nl

          example.run

          I18n.locale = original_locale
        end

        subject { gateway.capture(10, psp_reference, currency: currency) }

        let(:method) { :capture_payment }
        let(:expected_reponse_string) { 'Betaling mislukt' }

        include_examples 'a failed adyen response'
      end
    end
  end

  private

  def message(response)
    if response.success?
      response.result_code
    else
      translation = ::SolidusAdyenCse::RefusalReasonTranslation.new(response.refusal_reason)

      Spree.t(translation.key, scope: 'adyen_cse.gateway_errors', default: translation.default_text)
    end
  end
end
