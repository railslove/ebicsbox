require 'grape'

require_relative '../models/transaction'

module Box
  class UniqueTransactionEref < Grape::Validations::Base
    def validate(request)
      organization = request.env['box.organization']

      eref_unused = organization
        .accounts_dataset.where(iban: request.params[:account])
        .left_join(:transactions, account_id: :id).where(transactions__eref: request.params[:end_to_end_reference])
        .empty?

      eref_unused or fail(Grape::Exceptions::Validation, params: [@scope.full_name(:end_to_end_reference)], message: "must be unique")
    end
  end
end
