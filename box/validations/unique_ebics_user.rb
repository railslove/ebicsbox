# frozen_string_literal: true

require 'grape'

require_relative '../models/ebics_user'

module Box
  class UniqueEbicsUser < Grape::Validations::Base
    def validate_param!(attr_name, params)
      scope = EbicsUser.association_join(:accounts)
                       .where(
                         accounts__iban: params[:account_id],
                         user_id: params[:user_id],
                         remote_user_id: params[:ebics_user]
                       )

      return if scope.none?

      raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: 'already setup for given account'
    end
  end
end
