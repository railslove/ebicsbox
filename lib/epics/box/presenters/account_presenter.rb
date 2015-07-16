class Epics::Box::AccountPresenter < Grape::Entity
  expose :name
  expose :bic
  expose :iban
  expose :creditor_identifier
  expose :bankname
  expose :activated_at
  expose :mode
end
