require 'openssl'

module Epics
  module Box
    class Event < Sequel::Model
      SUPPORTED_TYPES = [
        :debit_created, :debit_failed, :debit_succeeded,
        :credit_created, :credit_failed, :credit_suceeded,
        :statement_updated,
      ]

      def self.respond_to_missing?(method_name, include_private = false)
        SUPPORTED_TYPES.include?(method_name) || super
      end

      def self.method_missing(method_name, *args, &block)
        if SUPPORTED_TYPES.include?(method_name)
          publish(method_name, *args)
        else
          super # ignore and pass along
        end
      end

      def self.publish(event_type, payload = {})
        event = new type: event_type, payload: Sequel.pg_json(payload.stringify_keys), signature: signature(payload)
        event.save
      end

      def self.signature(payload)
        digest = OpenSSL::Digest.new('sha1')
        secret = Box.configuration.secret_token
        'sha1=' + OpenSSL::HMAC.hexdigest(digest, secret, payload.to_s)
      end
    end
  end
end
