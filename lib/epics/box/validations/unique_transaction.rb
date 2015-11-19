module Epics
  module Box
    class UniqueTransaction < Grape::Validations::Base
      def validate_param!(attr_name, params)
        unless DB[:transactions].where(attr_name => params[attr_name]).count == 0
          raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be unique"
        end
      end
    end
  end
end
