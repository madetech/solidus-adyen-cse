module Spree
  describe Order do
    let!(:order) { OrderWalkthrough.up_to(:delivery) }
    let!(:payment) { create_payment }

    let(:gateway) { create(:adyen_cse_payment_method, name: 'Adyen') }
    let(:credit_card) { create(:credit_card, payment_method: gateway) }
    let(:encrypted_card_data) { 'testtesttest' }
    let(:psp_reference) { 'ZAJxC6m69BJFDLvE' }
    let(:response) do
      double('Response', success?: true,
                         psp_reference: psp_reference,
                         result_code: 'Authorised')
    end

    before do
      expect(gateway.provider).to receive(:authorise_payment).and_return(response)
      expect(gateway.provider).to receive(:capture_payment).and_return(response)

      order.encrypted_card_data = {
        "#{gateway.id}": encrypted_card_data
      }
    end

    it 'transition to complete' do
      expect(order.state).to eq 'payment'

      order.next!

      payment.reload

      expect(payment.state).to eq('adyen_authorized')

      order.complete!

      expect(order.state).to eq('complete')

      expect(order.payments.first.source.default).to be false
    end

    context 'when there is an existing adyen_authorized payment' do
      let(:cancel_psp_reference) { 'ZAJxC6m69BJFDLvT' }
      let(:cancel_response) do
        double('CancelResponse', success?: true,
                                 psp_reference: cancel_psp_reference)
      end

      let!(:canceled_payment) { create_payment('adyen_authorized', cancel_psp_reference) }

      before do
        expect(gateway.provider).to receive(:cancel_payment)
          .with(cancel_psp_reference)
          .and_return(cancel_response)
      end

      it 'will cancel the previous' do
        create_payment

        order.next!

        order.complete!

        expect(canceled_payment.state).to eq('invalid')
      end
    end

    def create_payment(state = 'checkout', response_code = nil)
      order.payments.create!(
        amount: 1,
        source: credit_card,
        state: state,
        payment_method: gateway,
        response_code: response_code)
    end
  end
end
