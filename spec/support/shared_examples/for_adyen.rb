shared_examples 'a successful adyen response' do
  it { is_expected.to eq(psp_reference) }
end

shared_examples 'a failed adyen response' do
  it 'will return the correct psp_reference' do
    expect(subject.psp_reference).to eq(psp_reference)
  end

  it 'will return a refusal reason' do
    expect(subject.refusal_reason).to be_present
  end

  describe '#to_s' do
    it 'will combine the result_code and refusal_reason' do
      expect(subject.to_s).to eq(expected_reponse_string)
    end
  end
end
