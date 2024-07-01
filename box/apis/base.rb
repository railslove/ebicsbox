# frozen_string_literal: true

require "grape"

require_relative "v2/base"

module Box
  module Apis
    class Base < Grape::API
      mount Box::Apis::V2::Base
    end
  end
end
