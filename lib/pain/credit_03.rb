require 'nokogiri'
require 'bigdecimal'

module Pain
  class Credit03
    attr_accessor :doc

    def initialize(doc)
      self.doc = doc.at_xpath("/xmlns:Document/xmlns:CstmrCdtTrfInitn")
    end

    def to_h(options = {})
      {
        id: get_content("./xmlns:GrpHdr/xmlns:MsgId"),
        created_at: get_content("./xmlns:GrpHdr/xmlns:CreDtTm"),
        transactions_count: get_content("./xmlns:GrpHdr/xmlns:NbOfTxs").to_i,
        total_amount: BigDecimal.new(get_content("./xmlns:GrpHdr/xmlns:CtrlSum")),
        initiating_party: {
          name: get_content("./xmlns:GrpHdr/xmlns:InitgPty/xmlns:Nm")
        },
        payments: doc.xpath("./xmlns:PmtInf").map { |payment| payment_info(payment) }
      }
    end

    alias_method :to_hash, :to_h
    alias_method :as_json, :to_h

    protected

    def get_content(xpath, root = doc)
      root.at_xpath(xpath).try(:content)
    end

    def payment_info(payment)
      {
        id: get_content("./xmlns:PmtInfId", payment),
        execution_date: get_content("./xmlns:ReqdExctnDt", payment),
        account: get_content("./xmlns:Dbtr//xmlns:Nm", payment),
        iban: get_content("./xmlns:DbtrAcct/xmlns:Id/xmlns:IBAN", payment),
        bic: get_content("./xmlns:DbtrAgt/xmlns:FinInstnId/xmlns:BIC", payment),
        transactions: payment.xpath("./xmlns:CdtTrfTxInf").map { |trx| transaction(trx) },
      }
    end

    def transaction(transaction)
      {
        eref: get_content("./xmlns:PmtId/xmlns:EndToEndId", transaction),
        name: get_content("./xmlns:Cdtr/xmlns:Nm", transaction),
        amount: BigDecimal.new(get_content("./xmlns:Amt/xmlns:InstdAmt", transaction)),
        iban: get_content("./xmlns:CdtrAcct/xmlns:Id/xmlns:IBAN", transaction),
        bic: get_content("./xmlns:CdtrAgt/xmlns:FinInstnId/xmlns:BIC", transaction),
        remittance_information: get_content("./xmlns:RmtInf/xmlns:Ustrd", transaction),
      }
    end
  end
end
