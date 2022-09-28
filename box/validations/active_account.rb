# frozen_string_literal: true

require 'grape'

require_relative '../models/account'

module Box
  class ActiveAccount < Grape::Validations::Validators::Base
    def validate_param!(attr_name, params)
      account = Account.first!(iban: params[:id])
      if account.iban != params[:iban] && account.active?
        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: 'cannot be changed on active account'
      end
    end
  end
end
