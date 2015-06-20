module Epics
  RSpec.describe Box do
    it 'initializes the namespace' do
      expect(Epics::Box).to be_kind_of(Module)
    end

    describe '.configuration' do
      it 'returns a configuration instance' do
        expect(described_class.configuration).to be_instance_of(Box::Configuration)
      end
    end

    describe '.logger' do
      it 'returns a logger instance' do
        expect(described_class.logger).to be_instance_of(Logger)
      end
    end
  end
end
