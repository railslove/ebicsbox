require 'base64'

require_relative '../queue'
require_relative '../models/event'
require_relative '../models/transaction'

module Box
  module Jobs
    class Credit
      include Sidekiq::Worker
      sidekiq_options queue: 'credit'

      INSTRUMENT_MAPPING = Hash.new('AZV').update({
        "EUR" => :CCT,
      })

      def perform(message)
        message.symbolize_keys!
        transaction = Transaction.create(
          account_id: message[:account_id],
          user_id: message[:user_id],
          amount: message[:amount],
          type: "credit",
          payload: Base64.strict_decode64(message[:payload]),
          eref: message[:eref],
          currency: message[:currency],
          status: "created",
          order_type: INSTRUMENT_MAPPING[message[:currency]],
          metadata: message[:metadata]
        )

        transaction.execute!
        Event.credit_created(transaction)
        Queue.update_processing_status(message[:account_id])

        Box.logger.info("[Jobs::Credit] Created credit! transaction_id=#{transaction.id}")
      end
    end
  end
end
