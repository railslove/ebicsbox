class Epics::Box::Statement < Sequel::Model
  many_to_one :account
  many_to_one :transaction

  def self.paginated_by_account(account_id:, per_page: 10, page: 1, transaction_id: nil, **unused)
    query = self
      .where(account_id: account_id)
      .limit(per_page)
      .offset((page - 1) * per_page)
      .reverse_order(:date)

    # Filter by transaction id
    query = query.where(transaction_id: transaction_id) if transaction_id.present?

    query
  end

  def credit?
    !debit?
  end

  def debit?
    self.debit
  end

  def type
    debit? ? 'debit' : 'credit'
  end

  def as_event_payload
    transaction = Epics::Box::Transaction.where(eref: eref).first
    {
      account_id: account_id,
      statement: self.to_hash,
      transaction: transaction.nil? ? nil : transaction.to_hash
    }
  end
end
