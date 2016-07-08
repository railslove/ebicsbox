require 'base64'
require 'securerandom'
require 'sepa_king'

require_relative '../errors/business_process_failure'
require_relative '../queue'

module Box
  class DirectDebit
    def self.create!(account, params, user)
      sdd = SEPA::DirectDebit.new(account.pain_attributes_hash).tap do |debit|
        debit.message_identification= "EBICS-BOX/#{SecureRandom.hex(11).upcase}"
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
          payload: Base64.strict_encode64(sdd.to_xml),
          amount: params[:amount],
          eref: params[:eref],
          instrument: params[:instrument]
        )
      else
        fail Box::BusinessProcessFailure.new(sdd.errors)
      end
    rescue ArgumentError => e
      # TODO: Will be fixed upstream in the sepa_king gem by us
      fail Box::BusinessProcessFailure.new({base: e.message}, 'Invalid data')
    end

    def self.v2_create!(account, params, user)
      
      sdd = SEPA::DirectDebit.new(account.pain_attributes_hash).tap do |debit|
        debit.message_identification= "EBICS-BOX/#{SecureRandom.hex(11).upcase}"
        debit.add_transaction(
          name: params[:name],
          bic: params[:bic],
          iban: params[:iban],  
          amount: params[:amount_in_cents] / 100.0,
          mandate_id: params[:mandate_id],
          mandate_date_of_signature: params[:mandate_signature_date],
          reference: params[:end_to_end_reference],
          batch_booking: true,
          local_instrument: 'COR1',
          sequence_type: 'FRST'
        )
      end

      require 'byebug'
      byebug
      
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
        fail Box::BusinessProcessFailure.new(sdd.errors)
      end
    rescue ArgumentError => e
      # TODO: Will be fixed upstream in the sepa_king gem by us
      fail Box::BusinessProcessFailure.new({base: e.message}, 'Invalid data')
    end
  end
end
