module Epics
  module Box
    module Helpers
      module Default
        def current_user
          @current_user ||= begin
            if token = params['access_token'] || headers['Authorization'].to_s[/token (.+)/, 1]
              User.find_by_access_token(token)
            else
              nil
            end
          end
        end

        def current_organization
          @current_organization ||= current_user.organization
        end

        def account
          current_organization.find_account!(params[:account])
        end

        def logger
          Server.logger
        end
      end
    end
  end
end
