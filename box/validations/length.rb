# frozen_string_literal: true

require 'grape'

class Length < Grape::Validations::Base
  def validate_param!(attr_name, params)
    unless params[attr_name].length <= @option
      raise Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be at the most #{@option} characters long"
    end
  end
end
