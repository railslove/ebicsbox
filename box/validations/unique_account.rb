require 'grape'

require_relative '../models/account'

module Epics
  module Box
    class UniqueAccount < Grape::Validations::Base
      def validate_param!(attr_name, params)
        account = Account.first(attr_name => params[attr_name])

        adding_duplicate_iban = account.present? && params[:id].blank?
        changing_to_duplicate_iban = account.present? && params[:id].present? && params[:id] != account.iban

        if adding_duplicate_iban || changing_to_duplicate_iban
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be unique"
        end
      end
    end
  end
end
