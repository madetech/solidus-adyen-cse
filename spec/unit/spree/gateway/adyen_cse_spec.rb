describe Spree::Gateway::AdyenCse do
  let(:psp_reference) { '53880' }
  let(:currency) { 'GBP' }
  let(:success) { true }

  let(:credit_card) { create(:credit_card) }
  let(:gateway) { create(:adyen_cse_payment_method, name: 'Adyen') }

  let(:response) do
    double('Response', success?: success,
                       psp_reference: psp_reference)
  end


  describe '#capture' do
    before do
      expect(gateway.provider).to receive(:capture_payment).and_return(response)
    end

    subject { gateway.capture(10, psp_reference, currency: currency).authorization }

    it { is_expected.to eq(psp_reference) }
  end

  describe '#credit' do
    before do
      expect(gateway.provider).to receive(:cancel_or_refund_payment).and_return(response)
    end

    subject { gateway.credit(10, credit_card, psp_reference, currency: currency).authorization }

    it { is_expected.to eq(psp_reference) }
  end

  describe '#void' do
    before do
      expect(gateway.provider).to receive(:cancel_payment).and_return(response)
    end

    subject { gateway.void(psp_reference, credit_card).authorization }

    it { is_expected.to eq(psp_reference) }
  end
end
