module Epics
  module Box
    class ManageAccountPresenter < Grape::Entity
      # Generic data
      expose :iban
      expose :bic
      expose :bankname
      expose :creditor_identifier

      # Internal data
      expose :name
      expose :callback_url
      expose :mode

      # Ebics data
      expose :url
      expose :host
      expose :partner
      expose :user
      expose :ini_letter

      # Meta data
      expose :activated_at
      expose :submitted_at
      expose :state
    end
  end
end
