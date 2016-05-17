require 'grape'

require_relative '../models/transaction'

module Epics
  module Box
    class UniqueTransaction < Grape::Validations::Base
      def validate_param!(attr_name, params)
        unless Transaction.where(attr_name => params[attr_name]).count == 0
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be unique"
        end
      end
    end
  end
end
