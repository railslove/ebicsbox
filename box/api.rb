require_relative './apis/registration'
require_relative './apis/service'
require_relative './apis/management'
require_relative './apis/content'

module Box
  class Api < Grape::API
    mount Apis::Service
    mount Apis::Management
    mount Apis::Content
    mount Apis::Registration
  end
end
