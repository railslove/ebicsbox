class Epics::Box::StatementPresenter < Grape::Entity
  expose :name
  expose :bic
  expose :iban
  expose :amount
  expose :eref
  expose :mref
  expose :debit
  expose :date
  expose :remittance_information
  expose :creditor_identifier
  expose :object, as: :statement
  expose :transaction, with: Epics::Box::TransactionPresenter

  def remittance_information
    object[:svwz] || object[:information]
  end
end
