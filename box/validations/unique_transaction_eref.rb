# frozen_string_literal: true

require 'grape'

require_relative '../models/transaction'

module Box
  class UniqueTransactionEref < Grape::Validations::Validators::Base
    def validate(request)
      organization = request.env['box.organization']

      eref_unused = organization
                    .accounts_dataset.where(iban: request.params[:account])
                    .left_join(:transactions, account_id: :id).where(transactions__eref: request.params[:end_to_end_reference])
                    .empty?

      raise Grape::Exceptions::Validation.new(params: [@scope.full_name(:end_to_end_reference)], message: 'must be unique') unless eref_unused
    end
  end

  class LengthTransactionEref < Grape::Validations::Validators::Base
    def length(currency)
      Hash.new(27).update(
        'EUR' => 64
      )[currency]
    end

    def validate(request)
      return if request.params[:end_to_end_reference].to_s.size <= length(request.params[:currency])

      raise Grape::Exceptions::Validation.new(params: [@scope.full_name(:end_to_end_reference)], message: "must be at the most #{length(request.params[:currency])} characters long")
    end
  end
end
