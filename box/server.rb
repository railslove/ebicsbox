require 'grape'

require_relative './apis/content'
require_relative './apis/management'
require_relative './apis/registration'
require_relative './apis/service'

module Box
  class Server < Grape::API
    mount Box::Apis::Service
    mount Box::Apis::Management
    mount Box::Apis::Content
    mount Box::Apis::Registration
  end
end
