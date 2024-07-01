# frozen_string_literal: true

require 'grape'

require_relative '../models/account'

module Box
  class UniqueAccount < Grape::Validations::Validators::Base
    def validate(request)
      organization = request.env['box.organization']
      if request.post? && !organization.accounts_dataset.where(iban: request.params[:iban]).empty?
        raise Grape::Exceptions::Validation.new(params: [:iban], message: 'must be unique')
      end
    end
  end
end
