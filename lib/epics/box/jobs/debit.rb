module Epics
  module Box
    module Jobs
      class Debit
        INSTRUMENT_MAPPING = {
          "CORE" => :CDD,
          "COR1" => :CD1,
          "B2B" =>  :CDB,
        }

        def self.process!(message)
          transaction = Epics::Box::Transaction.create(
            type: "debit",
            order_type: INSTRUMENT_MAPPING[message[:instrument]],
            account_id: message[:account_id],
            eref: message[:eref],
            payload: Base64.strict_decode64(message[:payload]),
            status: "created",
          )

          transaction.execute!
          Queue.update_processing_status(message[:account_id])

          Box.logger.info("[Jobs::Debit] Created debit! transaction_id=#{transaction.id}")
        end
      end
    end
  end
end
