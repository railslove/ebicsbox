# frozen_string_literal: true

require "base64"
require "securerandom"
require "sepa_king"

require_relative "../errors/business_process_failure"
require_relative "../queue"

module Box
  class Credit
    def self.create!(account, params, user)
      sct = SEPA::CreditTransfer.new(account.credit_pain_attributes_hash).tap do |credit|
        credit.message_identification = "EBICS-BOX/#{SecureRandom.hex(11).upcase}"
        credit.add_transaction(
          name: params[:name],
          bic: params[:bic],
          iban: params[:iban],
          amount: params[:amount] / 100.0,
          reference: params[:eref],
          remittance_information: params[:remittance_information],
          requested_date: Time.at(params[:requested_date]).to_date,
          batch_booking: false,
          service_level: params[:service_level]
        )
      end

      if sct.valid?
        Queue.execute_credit(
          account_id: account.id,
          user_id: user.id,
          payload: Base64.strict_encode64(sct.to_xml("pain.001.001.03")),
          eref: params[:eref],
          currency: "EUR",
          amount: params[:amount],
          metadata: {
            **params.slice(:name, :iban, :bic, :reference),
            execution_date: params[:execution_date]&.iso8601
          }
        )
      else
        raise Box::BusinessProcessFailure, sct.errors
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

      # Set urgent flag or fall back to SEPA
      params[:service_level] = params[:urgent] ? "URGP" : "SEPA"

      create!(account, params, user)
    end
  end
end
