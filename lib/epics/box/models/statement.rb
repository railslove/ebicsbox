class Epics::Box::Statement < Sequel::Model
  def self.paginated_by_account(account_id, options = {})
    options = { per_page: 10, page: 1 }.merge(options)
    where(account_id: account_id).limit(options[:per_page]).offset((options[:page] - 1) * options[:per_page])
  end

  def credit?
    !debit?
  end

  def debit?
    self.debit
  end
end
