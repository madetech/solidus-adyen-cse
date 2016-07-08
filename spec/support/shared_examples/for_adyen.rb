shared_examples 'a successful adyen response' do
  it { is_expected.to eq(psp_reference) }
end

shared_examples 'a failed adyen response' do
  it 'will return the correct psp_reference' do
    expect(subject.authorization).to eq(psp_reference)
  end

  describe '#message' do
    it 'will combine the result_code and refusal_reason' do
      expect(subject.message).to eq(expected_reponse_string)
    end
  end
end
