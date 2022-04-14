# frozen_string_literal: true

require 'base64'

require_relative '../queue'
require_relative '../models/event'
require_relative '../models/transaction'

module Box
  module Jobs
    class Debit
      include Sidekiq::Worker
      sidekiq_options queue: 'debit'

      INSTRUMENT_MAPPING = {
        'CORE' => :CDD,
        'COR1' => :CD1,
        'B2B' => :CDB
      }.freeze

      def perform(message)
        message.symbolize_keys!
        transaction = Box::Transaction.find_or_create(user_id: message[:user_id], eref: message[:eref]) do |trx|
          trx.amount      = message[:amount]
          trx.type        = 'debit'
          trx.order_type  = INSTRUMENT_MAPPING[message[:instrument]]
          trx.account_id  = message[:account_id]
          trx.payload     = Base64.strict_decode64(message[:payload])
          trx.status      = 'created'
          trx.msg_id      = message[:message_identification]
        end

        return false unless transaction.status == 'created'

        transaction.execute!

        Event.debit_created(transaction)
        Queue.update_processing_status(message[:account_id])

        Box.logger.info("[Jobs::Debit] Created debit! transaction_id=#{transaction.id}")
      end
    end
  end
end
