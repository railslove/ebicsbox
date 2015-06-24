class Epics::Box::StatementPresenter < Grape::Entity
  expose :name
  expose :bic
  expose :iban
  expose :amount_cents, as: :amount
  expose :eref
  expose :mref
  expose :debit
  expose :date
  expose :remittance_information
  expose :creditor_identifier
  expose :object, as: :statement

  def remittance_information
    object[:svwz] || object[:information]
  end
end
