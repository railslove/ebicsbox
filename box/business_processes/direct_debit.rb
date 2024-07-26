# frozen_string_literal: true

require "base64"
require "securerandom"
require "sepa_king"

require_relative "../errors/business_process_failure"
require_relative "../queue"

module Box
  module BusinessProcesses
    class DirectDebit
      def self.create!(account, params, user)
        sdd = SEPA::DirectDebit.new(account.pain_attributes_hash).tap do |debit|
          debit.message_identification = "EBICS-BOX/#{SecureRandom.hex(11).upcase}"
          debit.add_transaction(
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
            payload: Base64.strict_encode64(sdd.to_xml("pain.008.001.02")),
            amount: params[:amount],
            eref: params[:eref],
            instrument: params[:instrument]
          )
        else
          raise Box::BusinessProcessFailure, sdd.errors
        end
      rescue ArgumentError => e
        # TODO: Will be fixed upstream in the sepa_king gem by us
        raise Box::BusinessProcessFailure.new({base: e.message}, "Invalid data")
      end

      def self.v2_create!(user, account, params)
        # EBICS requires a unix timestamp
        params[:requested_date] = params[:execution_date].to_time.to_i

        # Transform a few params
        params[:amount] = params[:amount_in_cents]
        params[:eref] = params[:end_to_end_reference]
        params[:remittance_information] = params[:reference]

        # Execute v1 method
        self.create!(account, params, user)
      end
    end
  end
end
