module Epics
  module Box
    module Helpers
      module Default
        def current_user
          @current_user ||= begin
            if match = env['Authorization'].to_s.match(/token (.+)/)
              User.find_by_access_token(match[1])
            else
              nil
            end
          end
        end

        def current_organization
          @current_organization ||= current_user.organization
        end

        def account
          current_organization.accounts_dataset.first!(iban: params[:account])
        end

        def logger
          Server.logger
        end
      end
    end
  end
end
