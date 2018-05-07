require 'king_dtaus'
require_relative '../errors/business_process_failure'

module Box
  class ForeignCredit
    class Payload < OpenStruct
      def sender
        KingDta::Account.new({
          owner_name:          account.name,
          bank_number:         account.bank_number,
          owner_country_code:  account.bank_country_code,
          bank_account_number: account.bank_account_number
        })
      end

      def receiver
        KingDta::Account.new({
          bank_bic:           params[:bic],
          owner_name:         params[:name],
          owner_country_code: params[:country_code],
          ** account_number
        })
      end

      def account_number
        if params[:iban] =~ /[A-Z]{2}/
          { bank_iban: params[:iban] }
        else
          { bank_account_number: params[:iban] }
        end
      end

      def amount
        params[:amount] / 100.0
      end

      def fee_handling
        {
          split: '00',
          sender: '01',
          receiver: '02',
        }[params[:fee_handling]]
      end

      def booking
        KingDta::Booking.new(receiver, amount, params[:eref], nil, params[:currency]).tap do |booking|
          booking.payment_type       = '00'
          booking.charge_bearer_code = fee_handling
        end
      end

      def create
        azv = KingDta::Dtazv.new(params[:execution_date])
        azv.account = sender
        azv.add(booking)

        azv.create
      end
    end

    def self.v2_create!(user, account, params)
      params[:requested_date] = params[:execution_date].to_time.to_i

      # Transform a few params
      params[:amount] = params[:amount_in_cents]
      params[:eref] = params[:end_to_end_reference]
      params[:remittance_information] = params[:reference]

      payload = Payload.new(account: account, params: params)

      Queue.execute_credit(
        account_id: account.id,
        user_id: user.id,
        payload: Base64.strict_encode64(payload.create),
        eref: params[:eref],
        currency: params[:currency],
        amount: params[:amount],
        metadata: params.slice(:name, :iban, :bic, :execution_date, :reference, :country_code, :fee_handling)
      )
    rescue ArgumentError => e
      # TODO: Will be fixed upstream in the sepa_king gem by us
      fail Box::BusinessProcessFailure.new({ base: e.message }, 'Invalid data')
    end
  end
end
