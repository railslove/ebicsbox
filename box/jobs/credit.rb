module Box
  module Jobs
    class Credit
      def self.process!(message)
        transaction = Transaction.create(
          account_id: message[:account_id],
          user_id: message[:user_id],
          amount: message[:amount],
          type: "credit",
          payload: Base64.strict_decode64(message[:payload]),
          eref: message[:eref],
          status: "created",
          order_type: :CCT
        )

        transaction.execute!
        Event.credit_created(transaction)
        Queue.update_processing_status(message[:account_id])

        Box.logger.info("[Jobs::Credit] Created credit! transaction_id=#{transaction.id}")
      end
    end
  end
end
