class Epics::Box::Statement < Sequel::Model
  def self.paginated_by_account(account_id, per_page: 10, page: 1)
    where(account_id: account_id).limit(per_page).offset((page - 1) * per_page)
  end

  def credit?
    !debit?
  end

  def debit?
    self.debit
  end
end
