module Box
  RSpec.describe Worker do
    describe '#process!' do
      it 'starts the queues processing' do
        expect_any_instance_of(Queue).to receive(:process!)
        subject.process!
      end
    end
  end
end
