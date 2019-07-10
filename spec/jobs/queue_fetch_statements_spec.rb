# frozen_string_literal: true

require 'spec_helper'
require 'json'

module Box
  module Jobs
    RSpec.describe QueueFetchStatements do
      subject(:job) { described_class.new }

      describe '#perform' do
        it 'queues processing status job for each account_id' do
          expect { job.perform([1, 2, 3]) }.to change(Box::Jobs::FetchStatements.jobs, :size).by(3)
        end

        it 'queues with account id' do
          job.perform([1337, 4711])

          queued_jobs = Box::Jobs::FetchStatements.jobs
          expect(queued_jobs.any? { |j| j['args'] == [1337, {}] }).to be_truthy
          expect(queued_jobs.any? { |j| j['args'] == [4711, {}] }).to be_truthy
        end
      end
    end
  end
end
