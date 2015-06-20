module Epics
  module Box
    module Jobs
      class Credit
        def self.process!(message)
          transaction = Epics::Box::Transaction.create(
            account_id: message[:account_id],
            type: "credit",
            payload: Base64.strict_decode64(message[:payload]),
            eref: message[:eref],
            status: "created",
            order_type: :CCT
          )

          transaction.execute!
          Queue.update_processing_status(message[:account_id])

          Box.logger.info("[Jobs::Credit] Created credit! transaction_id=#{transaction.id}")
        end
      end
    end
  end
end
