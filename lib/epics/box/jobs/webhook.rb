module Epics
  module Box
    module Jobs
      class Webhook
        def self.process!(message)
          account = Epics::Box::Account[message[:account_id]]

          message = if account.callback_url
            res = HTTParty.post(account.callback_url, body: message[:payload])
            "Callback triggered: #{res.code} #{res.parsed_response}"
          else
            "No callback configured for #{account.name}."
          end

          Box.logger.info("[Jobs::Webhook] #{message} account_id=#{account.id}")
        end
      end
    end
  end
end
