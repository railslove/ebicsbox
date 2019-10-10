# frozen_string_literal: true

require 'grape-entity'

module Box
  module Entities
    class WebhookDelivery < Grape::Entity
      expose :delivered_at
      expose :response_body
      expose :reponse_headers
      expose :response_status
      expose :response_time
    end
  end
end
