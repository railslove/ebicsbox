module Epics
  module Box
    class DirectDebit
      Failure = Class.new(RuntimeError) do
        attr_accessor :errors
        def initialize(errors, msg = nil)
          super(msg || errors.full_messages.join(" "))
          self.errors = errors
        end
      end

      def self.create!(account, params, user)
        sdd = SEPA::DirectDebit.new(account.pain_attributes_hash).tap do |credit|
          credit.message_identification= "EBICS-BOX/#{SecureRandom.hex(11).upcase}"
          credit.add_transaction(
            name: params[:name],
            bic: params[:bic],
            iban: params[:iban],
            amount: params[:amount] / 100.0,
            instruction: params[:instruction],
            mandate_id: params[:mandate_id],
            mandate_date_of_signature: Time.at(params[:mandate_signature_date]).to_date,
            local_instrument: params[:instrument],
            sequence_type: params[:sequence_type],
            reference: params[:eref],
            remittance_information: params[:remittance_information],
            requested_date: Time.at(params[:requested_date]).to_date,
            batch_booking: true
          )
        end

        if sdd.valid?
          Queue.execute_debit(
            account_id: account.id,
            user_id: user.id,
            payload: Base64.strict_encode64(sdd.to_xml),
            amount: params[:amount],
            eref: params[:eref],
            instrument: params[:instrument]
          )
        else
          fail Failure.new(sdd.errors)
        end
      rescue ArgumentError => e
        fail Failure.new({base: e.message}, 'Invalid data')
      end
    end
  end
end
