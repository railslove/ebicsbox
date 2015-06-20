module Epics
  module Box
    module Jobs
      class Debit
        def self.process!(message)
          transaction = Epics::Box::Transaction.create(
            type: "debit",
            order_type: Epics::Box::DEBIT_MAPPING[message[:instrument]],
            account_id: message[:account_id],
            eref: message[:eref],
            payload: Base64.strict_decode64(message[:payload]),
            status: "created",
          )

          transaction.execute!
          Queue.check_accounts(message[:account_id])

          Box.logger.info("[Jobs::Debit] Created debit! transaction_id=#{transaction.id}")
        end
      end
    end
  end
end
