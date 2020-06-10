# frozen_string_literal: true

require 'base64'

require_relative '../queue'
require_relative '../models/event'
require_relative '../models/transaction'

module Box
  module Jobs
    class Credit
      include Sidekiq::Worker
      sidekiq_options queue: 'credit', retry: 5

      INSTRUMENT_MAPPING = Hash.new('AZV').update(
        'EUR' => :CCT
      )

      def perform(message)
        message.symbolize_keys!
        transaction = Transaction.find_or_create(user_id: message[:user_id], eref: message[:eref]) do |trx|
          trx.account_id  = message[:account_id]
          trx.amount      = message[:amount]
          trx.type        = 'credit'
          trx.payload     = Base64.strict_decode64(message[:payload])
          trx.currency    = message[:currency]
          trx.status      = 'created'
          trx.order_type  = INSTRUMENT_MAPPING[message[:currency]]
          trx.metadata    = message[:metadata]
        end

        return false unless transaction.status == 'created'

        transaction.execute!

        Event.credit_created(transaction)
        Queue.update_processing_status(message[:account_id])

        Box.logger.info("[Jobs::Credit] Created credit! transaction_id=#{transaction.id}")
      end
    end
  end
end
