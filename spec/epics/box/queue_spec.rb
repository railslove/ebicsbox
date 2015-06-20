module Epics
  module Box
    RSpec.describe Queue do

      describe '.client' do
        it 'returns an instance of a beanstalk client' do
          expect(described_class.client).to be_an_instance_of(Beaneater)
        end
      end

      describe '#with_error_logging' do
        let(:logger) { double('Logger', error: true) }
        let(:exception) { StandardError.new('test') }

        it 'returns the original result' do
          expect(subject.with_error_logging { 'ok' }).to eq('ok')
        end

        it 're-raises any exception raised in its code block' do
          expect { subject.with_error_logging { raise exception } }.to raise_error(exception)
        end

        it 'logs any exception messages' do
          subject.logger = logger
          subject.with_error_logging { raise exception } rescue ''
          expect(logger).to have_received(:error).with("[Queue] Failed job. message='test'")
        end
      end
    end
  end
end
