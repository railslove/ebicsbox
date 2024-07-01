# frozen_string_literal: true

require_relative "../../box/models/transaction"

def generate_credit_payload
  %(
    <?xml version="1.0" encoding="UTF-8"?>
    <Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.003.03" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.001.003.03 pain.001.003.03.xsd">
      <CstmrCdtTrfInitn>
        <GrpHdr>
          <MsgId>EBICS-BOX/5862E16C33CAFFEEBB23FF</MsgId>
          <CreDtTm>2015-12-18T13:19:08+01:00</CreDtTm>
          <NbOfTxs>1</NbOfTxs>
          <CtrlSum>1.23</CtrlSum>
          <InitgPty>
            <Nm>Test Konto BV</Nm>
          </InitgPty>
        </GrpHdr>
        <PmtInf>
          <PmtInfId>EBICS-BOX/5862E16C33CAFFEEBB23FF/1</PmtInfId>
          <PmtMtd>TRF</PmtMtd>
          <BtchBookg>true</BtchBookg>
          <NbOfTxs>1</NbOfTxs>
          <CtrlSum>1.23</CtrlSum>
          <PmtTpInf>
            <SvcLvl>
              <Cd>SEPA</Cd>
            </SvcLvl>
          </PmtTpInf>
          <ReqdExctnDt>2015-12-18</ReqdExctnDt>
          <Dbtr>
            <Nm>Test Konto BV</Nm>
          </Dbtr>
          <DbtrAcct>
            <Id>
              <IBAN>DE36250400900001234555</IBAN>
            </Id>
          </DbtrAcct>
          <DbtrAgt>
            <FinInstnId>
              <BIC>XBANDECG</BIC>
            </FinInstnId>
          </DbtrAgt>
          <ChrgBr>SLEV</ChrgBr>
          <CdtTrfTxInf>
            <PmtId>
              <EndToEndId>bv-test-java-1</EndToEndId>
            </PmtId>
            <Amt>
              <InstdAmt Ccy="EUR">1.23</InstdAmt>
            </Amt>
            <CdtrAgt>
              <FinInstnId>
                <BIC>DEUTDEMM760</BIC>
              </FinInstnId>
            </CdtrAgt>
            <Cdtr>
              <Nm>Max Mustermann</Nm>
            </Cdtr>
            <CdtrAcct>
              <Id>
                <IBAN>DE10375700240868353400</IBAN>
              </Id>
            </CdtrAcct>
            <RmtInf>
              <Ustrd>Testuberweisung fur BV Prasentation</Ustrd>
            </RmtInf>
          </CdtTrfTxInf>
        </PmtInf>
      </CstmrCdtTrfInitn>
    </Document>
  )
end

Fabricator(:credit, from: "Box::Transaction") do
  eref { Fabricate.sequence(:credit) { |i| "credit-#{i}" } }
  type "credit"
  payload { generate_credit_payload }
  ebics_transaction_id "B00U"
  status { %w[created file_upload funds_debited].sample }
  account_id 1
  order_type "CCT"
  amount 123_45
  user_id 1
end
