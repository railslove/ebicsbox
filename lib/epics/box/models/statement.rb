class Epics::Box::Statement < Sequel::Model
  def credit?
    !debit?
  end

  def debit?
    self.debit
  end
end
