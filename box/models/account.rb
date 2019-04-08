require 'sequel'
require 'securerandom'

module Box
  class Account < Sequel::Model
    class Config
      attr_accessor :config

      def initialize(config_hash)
        self.config = OpenStruct.new(config_hash)
      end

      def activation_check_interval
        config.activation_check_interval || Box.configuration.activation_check_interval
      end
    end

    self.raise_on_save_failure = true

    NoTransportClient = Class.new(StandardError)
    NotActivated = Class.new(StandardError)
    NotFound = Class.new(ArgumentError) do
      attr_accessor :organization_id, :iban

      def self.for_orga(organization_id:, iban:)
        new("Could not find account! iban=#{iban} organization_id=#{organization_id}").tap do |error|
          error.organization_id = organization_id
          error.iban = iban
        end
      end
    end

    one_to_many :bank_statements
    one_to_many :events
    one_to_many :statements
    one_to_many :ebics_users
    one_to_many :transactions
    many_to_one :organization

    dataset_module do
      def by_organization(organization)
        where(organization_id: organization.id)
      end

      def filtered(params)
        query = self
        # Filter by status
        query = case params[:status]
          when 'activated' then query.left_join(:ebics_users, account_id: :id).exclude(ebics_users__activated_at: nil)
          when 'not_activated' then query.left_join(:ebics_users, account_id: :id).where(ebics_users__activated_at: nil)
          else query
        end
        query
      end

      def paginate(params)
        limit(params[:per_page])
          .offset((params[:page] - 1) * params[:per_page])
          .order(:name)
      end
    end

    def config
      Config.new(super)
    end

    def transport_client
      @transport_client ||= begin
        base_scope = ebics_users_dataset.exclude(ebics_users__activated_at: nil)
        ebics_user = base_scope.where(ebics_users__signature_class: 'T').first || base_scope.first
        if ebics_user.nil?
          fail NoTransportClient, 'Please setup and activate at least one ebics_user with a transport signature'
        else
          ebics_user.client
        end
      end
    end

    def client_for(user_id)
      ebics_user_for(user_id).client
    end

    def ebics_user_for(user_id)
      ebics_users_dataset.first(user_id: user_id)
    end

    def self.all_active_ids
      join(:ebics_users, :account_id => :id).select(:accounts__id).exclude(ebics_users__activated_at: nil).map(&:id)
    end

    def active?
      ebics_users.any?(&:active?)
    end

    def status
      active? ? 'activated' : 'not_activated'
    end

    def pain_attributes_hash
      fail(NotActivated) unless active?
      values.slice(:name, :bic, :iban, :creditor_identifier)
    end

    def credit_pain_attributes_hash
      fail(NotActivated) unless active?
      values.slice(:name, :bic, :iban)
    end

    def bank_account_number
      @bank_account_number ||= (bank_account_metadata; @bank_account_number)
    end

    def bank_number
      @bank_number ||= (bank_account_metadata; @bank_number)
    end

    def bank_country_code
      iban[0...2]
    end

    def bank_account_metadata
      Nokogiri::XML(transport_client.HTD).tap do |htd|
        @bank_account_number ||= htd.at_xpath("//xmlns:AccountNumber[@international='false']", xmlns: "urn:org:ebics:H004").text
        @bank_number         ||= htd.at_xpath("//xmlns:BankCode[@international='false']", xmlns: "urn:org:ebics:H004").text
      end
    end

    def last_imported_at
      DB[:imports].where(account_id: id).order(:date).last.try(:[], :date)
    end

    def imported_at!(date)
      DB[:imports].insert(date: date, account_id: id)
    end

    def set_balance(date, amount_in_cents)
      self.balance_date = date
      self.balance_in_cents = amount_in_cents
      save
    end

    def add_unique_ebics_user(user_id, ebics_user)
      DB.transaction do
        if !!ebics_user_for(user_id)
          fail('This user already has a ebics_user for this account.')
        end

        if ebics_users_dataset.where(remote_user_id: ebics_user).any?
          fail('Another user is using the same EBICS user id.')
        end

        if !(ebics_user = add_ebics_user(user_id: user_id, remote_user_id: ebics_user)) || !ebics_user.setup!
          fail('Failed to create ebics_user.')
        end
      end
    end

    def as_event_payload
      {
        account_id: id,
        account: self.to_hash,
      }
    end
  end
end
