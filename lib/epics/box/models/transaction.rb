require 'epics/box/models/event'

class Ebics::Box::Transaction < Sequel::Model

  many_to_one :account
  one_to_many :statements

  def set_state_from(action, reason_code = nil)
    old_status = status
    case
    when action == "file_upload" && status == "created"
      self.set(status: "file_upload")
    when action == "es_verification" && status == "file_upload"
      self.set(status: "es_verification")
    when action == "order_hac_final_pos" && status == "es_verification"
      self.set(status: "order_hac_final_pos")
    when action == "order_hac_final_neg" && status == "es_verification"
      self.set(status: "order_hac_final_neg")
    when action == "credit_received" && type == "debit"
      self.set(status: "funds_credited")
    when action == "debit_received" && type == "credit"
      self.set(status: "funds_debited")
    when action == "debit_received" && type == "debit"
      self.set(status: "funds_charged_back")
    end

    self.save

    if old_status != status
      Ebics::Box::Event.transaction_updated(self)
    end

    self.status
  end

  def execute!
    return if ebics_transaction_id.present?

    transaction_id, order_id = account.client.public_send(order_type, payload)
    update(ebics_order_id: order_id, ebics_transaction_id: transaction_id)
  end

  def as_event_payload
    {
      account_id: account_id,
      transaction: {
        id: id,
        eref: eref,
        type: type,
        ebics_order_id: ebics_order_id,
        ebics_transaction_id: ebics_transaction_id,
      }
    }
  end
end
