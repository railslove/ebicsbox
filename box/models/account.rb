require 'securerandom'

class Box::Account < Sequel::Model
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

  one_to_many :statements
  one_to_many :subscribers
  one_to_many :transactions
  many_to_one :organization

  def transport_client
    @transport_client ||= begin
      base_scope = subscribers_dataset.exclude(subscribers__activated_at: nil)
      subscriber = base_scope.where(subscribers__signature_class: 'T').first || base_scope.first
      if subscriber.nil?
        fail NoTransportClient, 'Please setup and activate at least one subscriber with a transport signature'
      else
        subscriber.client
      end
    end
  end

  def client_for(user_id)
    subscribers_dataset.first!(user_id: user_id).client
  end

  def self.all_active_ids
    join(:subscribers, :account_id => :id).select(:accounts__id).exclude(subscribers__activated_at: nil).map(&:id)
  end

  def active?
    subscribers.any?(&:active?)
  end

  def pain_attributes_hash
    fail(NotActivated) unless active?
    values.slice(:name, :bic, :iban, :creditor_identifier)
  end

  def credit_pain_attributes_hash
    fail(NotActivated) unless active?
    values.slice(:name, :bic, :iban)
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

  def as_event_payload
    {
      account_id: id,
      account: self.to_hash,
    }
  end
end
