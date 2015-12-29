class Epics::Box::Statement < Sequel::Model
  many_to_one :account
  many_to_one :transaction

  def self.generic_filter(query, account_id:, transaction_id: nil, from: nil, to: nil, **unused)
    # Filter by account id
    query = query.where(account_id: account_id)

    # Filter by transaction id
    query = query.where(transaction_id: transaction_id) if transaction_id.present?

    # Filter by statement date
    query = query.where("statements.date >= ?", from) if from.present?
    query = query.where("statements.date <= ?", to) if to.present?

    query
  end

  def self.count_by_account(**generic_filters)
    query = generic_filter(self, generic_filters)
    query.count
  end

  def self.paginated_by_account(per_page: 10, page: 1, **generic_filters)
    query = self.limit(per_page).offset((page - 1) * per_page).reverse_order(:date)
    generic_filter(query, generic_filters)
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
