class Unique < Grape::Validations::Base
  def validate_param!(attr_name, params)
    unless Epics::Box::DB[:transactions].where(attr_name => params[attr_name]).count == 0
      raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be unique"
    end
  end
end

module Epics
  module Box
    class Server < Grape::API

      helpers do
        def queue
          @queue ||= Epics::Box::QUEUE.new
        end
        def db
          @db ||= Epics::Box::DB
        end
      end

      params do
        requires :name,  type: String, desc: "the customers name"
        requires :bic ,  type: String, desc: "the customers bic" # TODO validate / clearer
        requires :iban ,  type: String, desc: "the customers iban" # TODO validate
        requires :amount,  type: Integer, desc: "amount to credit", values: 1..12000000
        requires :eref,  type: String, desc: "end to end id", unique: true
        requires :mandate_id,  type: String, desc: "mandate id"
        requires :mandate_signature_date, type: Integer, desc: "mandate signature date"
        optional :instrument, type: String, desc: "", values: ["CORE", "COR1", "B2B"], default: "COR1"
        optional :sequence_type, type: String, desc: "", values: ["FRST", "RCUR", "OOFF", "FNAL"], default: "FRST"
        optional :remittance_information ,  type: String, desc: "will apear on the customers bank statement"
        optional :instruction ,  type: String, desc: "instruction identification, will not be submitted to the debtor"
        optional :requested_date,  type: Integer, desc: "requested execution date", default: ->{ Time.now.to_i } #TODO validate, future
      end
      desc "debits a customer account"
      post :debits do
        account = OpenStruct.new(name: "Box Gmbh", bic: "BANKDEFFXXX", iban: "DE87200500001234567890", creditor_identifier: "DE98ZZZ09999999999" )

        begin
          sdd = SEPA::DirectDebit.new(account.to_h).tap do |credit|
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

          fail(RuntimeError.new(sdd.errors.full_messages.join(" "))) unless sdd.valid?

          queue.publish 'debit', {payload: Base64.strict_encode64(sdd.to_xml), eref: params[:eref], instrument: params[:instrument]}

          {debit: 'ok'}
        rescue RuntimeError, ArgumentError => e
          {debit: 'nok', error: e.message}
        end
      end

      params do
        requires :name,  type: String, desc: "the customers name"
        requires :bic ,  type: String, desc: "the customers bic"
        requires :iban ,  type: String, desc: "the customers iban"
        requires :amount,  type: Integer, desc: "amount to credit", values: 1..12000000
        requires :eref,  type: String, desc: "end to end id", unique: true
        optional :remittance_information ,  type: String, desc: "will apear on the customers bank statement"
        optional :requested_date,  type: Integer, desc: "requested execution date", default: ->{ Time.now.to_i }
        optional :service_level, type: String, desc: "requested execution date", default: "SEPA", values: ["SEPA", "URGP"]
      end
      desc "Credits a customer account"
      post :credits do
        account = OpenStruct.new(name: "Box Gmbh", bic: "BANKDEFFXXX", iban: "DE87200500001234567890")

        begin
          sct = SEPA::CreditTransfer.new(account.to_h).tap do |credit|
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

          fail(RuntimeError.new(sct.errors.full_messages.join(" "))) unless sct.valid?

          queue.publish 'credit', {payload: Base64.strict_encode64(sct.to_xml), eref: params[:eref]}

          {credit: 'ok'}
        rescue RuntimeError, ArgumentError => e
          {credit: 'nok', errors: sct.errors.to_hash}
        end
      end

      params do
        optional :from,  type: Integer, desc: "results starting at"
        optional :to,    type: Integer, desc: "results ending at"
        optional :page,  type: Integer, desc: "page through the results", default: 1
        optional :per_page,  type: Integer, desc: "how many results per page", values: 1..100, default: 10
      end
      desc "Returns statements"
      get :statements do
        db[:statements].limit(params[:per_page]).offset((params[:page] -1) * params[:per_page]).all
      end
    end
  end
end
