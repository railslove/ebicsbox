class Epics::Box::TransactionPresenter < Grape::Entity
  expose :eref
  expose :type
  expose :status
  expose :order_type
end
