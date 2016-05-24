require 'grape'

require_relative '../models/account'

module Box
  class UniqueAccount < Grape::Validations::Base
    def validate(request)
      organization = request.env['box.organization']
      if request.post? && !organization.accounts_dataset.where(iban: request.params[:iban]).empty?
        raise Grape::Exceptions::Validation, params: [:iban], message: "must be unique"
      end
    end
  end
end
