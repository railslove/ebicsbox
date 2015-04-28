class Ebics::Box::Transaction < Sequel::Model

  many_to_one :account
  one_to_many :statements

  def set_state_from(action, reason_code = nil)
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

    self.status
  end

end
