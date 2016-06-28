require 'sequel'

require_relative '../../lib/pain'

require_relative './account'
require_relative './event'
require_relative './statement'
require_relative './user'

module Box
  class Transaction < Sequel::Model

    many_to_one :account
    many_to_one :user
    one_to_many :statements

    def_dataset_method(:by_organization) do |organization|
      left_join(:accounts, id: :account_id)
      .where(accounts__organization_id: organization.id)
      .select_all(:transactions)
    end

    def_dataset_method(:credit_transfers) do
      where(type: 'credit')
    end

    def_dataset_method(:filtered) do |params|
      query = self

      # Filter by account id
      if params[:iban].present?
        query = query.where(accounts__iban: params[:iban])
      end

      query
    end

    def_dataset_method(:paginate) do |params|
      limit(params[:per_page])
        .offset((params[:page] - 1) * params[:per_page])
        .reverse_order(:id)
    end

    def self.count_by_account(account_id, options = {})
      where(account_id: account_id).count
    end

    def self.paginated_by_account(account_id, options = {})
      options = { per_page: 10, page: 1 }.merge(options)
      where(account_id: account_id).limit(options[:per_page]).offset((options[:page] - 1) * options[:per_page]).reverse_order(:id)
    end

    def history
      super || []
    end

    def update_status(new_status, reason: nil)
      old_status = status

      update(
        history: self.history << { at: Time.now, status: new_status, reason: reason},
        status: get_status(new_status)
      )

      if old_status != status
        Event.transaction_updated(self)
      end

      return status
    end

    def get_status(new_status)
      case
        when new_status == "file_upload" && status == "created" then "file_upload"
        when new_status == "es_verification" && status == "file_upload" then "es_verification"
        when new_status == "order_hac_final_pos" && status == "es_verification" then "order_hac_final_pos"
        when new_status == "order_hac_final_neg" && status == "es_verification" then "order_hac_final_neg"
        when new_status == "credit_received" && type == "debit" then "funds_credited"
        when new_status == "debit_received" && type == "credit" then "funds_debited"
        when new_status == "debit_received" && type == "debit" then "funds_charged_back"
        else status
      end
    end

    def execute!
      return if ebics_transaction_id.present?
      transaction_id, order_id = account.client_for(user.id).public_send(order_type, payload)
      update(ebics_order_id: order_id, ebics_transaction_id: transaction_id)
    end

    def parsed_payload
      @parsed_payload ||= Pain.from_xml(payload).to_h
    rescue Pain::UnknownInput => ex
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
          ebics_transaction_id: ebics_transaction_id,
        }
      }
    end
  end
end
