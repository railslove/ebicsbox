RSpec.describe Epics::Box::Statement do
  describe '#credit?' do
    it 'returns true if record is a credit' do
      subject.debit = false
      expect(subject.credit?).to eq(true)
    end

    it 'returns false if record is a debig' do
      subject.debit = true
      expect(subject.credit?).to eq(false)
    end
  end

  describe '#debit?' do
    it 'returns true if record is a debit' do
      subject.debit = true
      expect(subject.debit?).to eq(true)
    end

    it 'returns false if record is a debig' do
      subject.debit = false
      expect(subject.debit?).to eq(false)
    end
  end
end
