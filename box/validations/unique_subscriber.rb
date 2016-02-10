require 'grape'

require_relative '../models/subscriber'

module Box
  class UniqueSubscriber < Grape::Validations::Base
    def validate_param!(attr_name, params)
      scope = Subscriber
        .join(:accounts, id: :account_id)
        .where(iban: params[:account_id], user_id: params[:user_id], remote_user_id: params[:ebics_user])
      unless 0 == scope.count
        raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "already setup for given account"
      end
    end
  end
end
