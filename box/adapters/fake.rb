require 'nokogiri'

module Box
  module Adapters
    class Fake
      attr_accessor :setup_args

      def initialize(*args)
        self.setup_args = args
      end

      def self.setup(*args)
        return new(*args)
      end

      def ini_letter(name)
        "Here would be the INI letter you would need to sign for your bank."
      end

      def INI
        true
      end

      def HIA
        true
      end

      def HPB
        true
      end

      def dump_keys
        "{}"
      end

      def STA(from = nil, to = nil)
        # Create a random number of statements every day
        ::File.read( ::File.expand_path("~/sta.mt940"))
      end

      def VMK(from = nil, to = nil)
        # Create a random number of statements every day
        ::File.read( ::File.expand_path("~/vmk.mt942"))
      end

      def HAC(from = nil, to = nil)
        ::File.open( ::File.expand_path("~/hac_empty.xml"))
      end

      def HTD
        ::File.open( ::File.expand_path("~/htd.xml"))
      end

      def CD1(pain)
        ["TRX#{SecureRandom.hex(6)}", "N#{SecureRandom.hex(6)}"]
      end
      alias :CDD :CD1
      alias :CDB :CD1

      def CCT(pain)
        doc = Nokogiri::XML(pain)
        ["TRX#{SecureRandom.hex(6)}", "N#{SecureRandom.hex(6)}"]
        trx = doc.css("Document CstmrCdtTrfInitn PmtInf CdtTrfTxInf")
        eref = trx.css("PmtId EndToEndId").text
        desc = trx.css("RmtInf Ustrd").text
        amount = trx.css("Amt InstdAmt").text.gsub(/\./, '').to_i
        transaction = Transaction[eref: eref]
        transaction.update_status("debit_received", reason: "Auto accept fake credit transfers")

        statement = Statement.create({
          account_id: transaction.account_id,
          sha: Digest::SHA2.hexdigest(SecureRandom.hex(12)).to_s,
          date: Date.today,
          entry_date: Date.today,
          amount: amount,
          sign: 1,
          debit: false,
          swift_code: "",
          reference: desc,
          bank_reference: "",
          bic: trx.css("CdtrAgt FinInstnId BIC").text,
          iban: trx.css("CdtrAcct Id IBAN").text,
          name: trx.css("Cdtr Nm").text,
          information: desc,
          description: desc,
          eref: eref,
        })

        Event.statement_created(statement)
        ["TRX#{SecureRandom.hex(6)}", "N#{SecureRandom.hex(6)}"]
      end

      def AZV(dtazv)
        ["TRX#{SecureRandom.hex(6)}", "N#{SecureRandom.hex(6)}"]
      end
    end
  end
end
