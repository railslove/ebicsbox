require 'epics/box/errors/business_process_failure'

module Epics
  module Box
    class Credit
      def self.create!(account, params, user)
        sct = SEPA::CreditTransfer.new(account.credit_pain_attributes_hash).tap do |credit|
          credit.message_identification= "EBICS-BOX/#{SecureRandom.hex(11).upcase}"
          credit.add_transaction(
            name: params[:name],
            bic: params[:bic],
            iban: params[:iban],
            amount: params[:amount] / 100.0,
            reference: params[:eref],
            remittance_information: params[:remittance_information],
            requested_date: Time.at(params[:requested_date]).to_date,
            batch_booking: true,
            service_level: params[:service_level]
          )
        end

        if sct.valid?
          Queue.execute_credit(
            account_id: account.id,
            user_id: user.id,
            payload: Base64.strict_encode64(sct.to_xml),
            eref: params[:eref],
            amount: params[:amount]
          )
        else
          fail(BusinessProcessFailure.new(sct.errors.full_messages.join(" ")))
        end
      rescue ArgumentError => e
        # TODO: Will be fixed upstream in the sepa_king gem by us
        fail BusinessProcessFailure.new({ base: e.message }, 'Invalid data')
      end
    end
  end
end
