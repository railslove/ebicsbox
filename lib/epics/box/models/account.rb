require 'securerandom'
class Epics::Box::Account < Sequel::Model
  self.raise_on_save_failure = true

  NoTransportClient = Class.new(StandardError)

  one_to_many :statements
  one_to_many :subscribers
  one_to_many :transactions
  many_to_one :organization

  def transport_client
    subscribers_dataset.where(subscribers__signature_class: 'T').exclude(subscribers__activated_at: nil).first!.client
  rescue Sequel::NoMatchingRow => ex
    fail NoTransportClient, 'Please setup and activate at least one subscriber with a transport signature'
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
    values.slice(:name, :bic, :iban, :creditor_identifier)
  end

  def credit_pain_attributes_hash
    values.slice(:name, :bic, :iban)
  end

  def last_imported_at
    DB[:imports].where(account_id: id).order(:date).last.try(:[], :date)
  end

  def imported_at!(date)
    DB[:imports].insert(date: date, account_id: id)
  end

  def as_event_payload
    {
      account_id: id,
      account: self.to_hash,
    }
  end
end
