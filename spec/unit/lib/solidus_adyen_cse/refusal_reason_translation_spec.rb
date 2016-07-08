describe SolidusAdyenCse::RefusalReasonTranslation do
  let(:refusal_reason) { '101 Made up texts' }

  let(:translation) { described_class.new(refusal_reason) }

  context '#key' do
    subject { translation.key }

    context 'when refusal reason contains an error code' do
      it { is_expected.to eq(:'101') }
    end

    context 'when refusal reason is a string' do
      let(:refusal_reason) { 'Rufused' }

      it { is_expected.to eq(:rufused) }

      context 'when refusal reason is a contains a not-word character' do
        let(:refusal_reason) { 'Rufused: because-stuff' }

        it { is_expected.to eq(:rufusedbecausestuff) }
      end
    end
  end

  context '#default_text' do
    subject { translation.default_text }

    context 'when refusal reason contains an error code' do
      it { is_expected.to eq('Made up texts') }
    end

    context 'when refusal reason is a string' do
      let(:refusal_reason) { 'Rufused' }

      it { is_expected.to eq('Rufused') }
    end
  end
end
