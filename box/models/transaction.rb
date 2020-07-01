# frozen_string_literal: true

require 'sequel'

require_relative '../../lib/pain'

require_relative './account'
require_relative './event'
require_relative './statement'
require_relative './user'

module Box
  class Transaction < Sequel::Model
    ID_REGEX = Regexp.new('([a-f\d]{8}(-[a-f\d]{4}){3}-[a-f\d]{12}?)', Regexp::IGNORECASE)

    plugin :dirty

    many_to_one :account
    many_to_one :user
    one_to_many :statements

    dataset_module do
      where(:credit_transfers, type: 'credit')
      where(:direct_debits, type: 'debit')

      def by_organization(organization)
        left_join(:accounts, id: :account_id)
          .where(accounts__organization_id: organization.id)
          .select_all(:transactions)
      end

      def filtered(params)
        query = self

        # Filter by account iban, status
        query = query.where(accounts__iban: params[:iban]) if params[:iban].present?
        query = query.where(status: params[:status]) if params[:status].present?

        query
      end

      def paginate(params)
        limit(params[:per_page])
          .offset((params[:page] - 1) * params[:per_page])
          .reverse_order(:id)
      end
    end

    def self.count_by_account(account_id, _options = {})
      where(account_id: account_id).count
    end

    def self.paginated_by_account(account_id, options = {})
      options = { per_page: 10, page: 1 }.merge(options)
      where(account_id: account_id).limit(options[:per_page]).offset((options[:page] - 1) * options[:per_page]).reverse_order(:id)
    end

    def history
      super || []
    end

    def make_history(reason, status = self.status)
      update(history: history.dup << { at: Time.now, status: status, reason: reason })
    end

    def update_status(new_status, reason: nil)
      self.status = get_status(new_status)

      if column_changed?(:status)
        make_history(reason, status)
        Event.method("#{type}_status_changed").call(self)
      end

      status
    end

    def get_status(new_status)
      if new_status == 'file_upload' && status == 'created' then 'file_upload'
      elsif new_status == 'es_verification' && status == 'file_upload' then 'es_verification'
      elsif new_status == 'order_hac_final_pos' && status == 'es_verification' then 'order_hac_final_pos'
      elsif new_status == 'order_hac_final_neg' && status == 'es_verification' then 'order_hac_final_neg'
      elsif new_status == 'credit_received' && type == 'debit' then 'funds_credited'
      elsif new_status == 'debit_received' && type == 'credit' then 'funds_debited'
      elsif new_status == 'debit_received' && type == 'debit' then 'funds_charged_back'
      elsif new_status == 'failed' then 'failed'
      else status
      end
    end

    def execute!
      return if ebics_transaction_id.present?

      transaction_id, order_id = account.client_for(user.id).public_send(order_type, payload)
      update(ebics_order_id: order_id, ebics_transaction_id: transaction_id)
    rescue Epics::Error => e
      Box.logger.warn { "Could not execute payload for transaction. id=#{id} message=#{e.message}" }
      update_status('failed', reason: "#{e.code}/#{e.message}")
    rescue Faraday::Error => e
      Box.logger.warn { "Request failed. id=#{id} message=#{e.message}" }
      make_history(e.message)
      raise(e)
    rescue StandardError => e
      Box.logger.warn { "Request failed. id=#{id} message=#{e.message}" }
      make_history(e.message)
    end

    def parsed_payload
      @parsed_payload ||= Pain.from_xml(payload).to_h
    rescue Pain::UnknownInput => _ex
      Box.logger.warn { "Could not parse payload for transaction. id=#{id}" }
      nil
    end

    def as_event_payload
      {
        id: public_id,
        account_id: account_id,
        transaction: {
          id: id,
          eref: eref,
          type: type,
          status: status,
          ebics_order_id: ebics_order_id,
          ebics_transaction_id: ebics_transaction_id
        }
      }
    end
  end
end
