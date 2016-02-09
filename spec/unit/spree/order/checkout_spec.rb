module Spree
  describe Order do
    context 'with an associated user' do
      let(:order) { OrderWalkthrough.up_to(:delivery) }
      let(:credit_card) { create(:credit_card) }

      let(:gateway) { create(:adyen_cse_payment_method, name: 'Adyen') }

      let(:response) do
        double('Response', success?: true,
                           psp_reference: 'ZAJxC6m69BJFDLvE',
                           result_code: 'Authorised')
      end

      let(:details) do
        double('Details', details: [
          { card: { number: '1111', expiry_date: 1.year.from_now }, recurring_detail_reference: 123 }
        ])
      end

      before do
        expect(gateway.provider).to receive(:authorise_payment).and_return(response)
      end

      it 'transitions to complete' do
        expect(order.state).to eq 'payment'

        order.payments.create! do |p|
          p.amount = 1
          p.source = credit_card
          p.payment_method = gateway
        end

        order.next!
        order.complete!

        expect(order.state).to eq('complete')
      end
    end
  end
end
