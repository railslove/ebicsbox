# frozen_string_literal: true

require 'sidekiq-scheduler'
require 'nokogiri'

module Box
  module Jobs
    class QueueProcessingStatus
      include Sidekiq::Worker
      sidekiq_options queue: 'check.orders', retry: false

      def perform(account_ids = [])
        log(:debug, 'Check orders.')
        account_ids = Account.all_active_ids if account_ids.empty?

        account_ids.each do |account_id|
          FetchProcessingStatus.perform_async(account_id)
        end
      end

      private

      def log(type, message, data = {})
        data = data.map { |k, v| "#{k}=#{v}" }.join(' ')
        Box.logger.public_send(type, "[#{self.class.name}] #{message} #{data}")
      end
    end
  end
end
