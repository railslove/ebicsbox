require_relative '../../box/models/transaction'

def generate_payload
  %{
    <?xml version="1.0" encoding="UTF-8"?>
    <Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.008.003.02" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:iso:std:iso:20022:tech:xsd:pain.008.003.02 pain.008.003.02.xsd">
      <CstmrDrctDbtInitn>
        <GrpHdr>
          <MsgId>EBICS-BOX/091289075DAA0AD81C0659</MsgId>
          <CreDtTm>2016-01-25T16:58:37+01:00</CreDtTm>
          <NbOfTxs>1</NbOfTxs>
          <CtrlSum>1.23</CtrlSum>
          <InitgPty>
            <Nm>Test Account</Nm>
            <Id>
              <OrgId>
                <Othr>
                  <Id>DE98ZZZ09999999999</Id>
                </Othr>
              </OrgId>
            </Id>
          </InitgPty>
        </GrpHdr>
        <PmtInf>
          <PmtInfId>EBICS-BOX/091289075DAA0AD81C0659/1</PmtInfId>
          <PmtMtd>DD</PmtMtd>
          <BtchBookg>true</BtchBookg>
          <NbOfTxs>1</NbOfTxs>
          <CtrlSum>1.23</CtrlSum>
          <PmtTpInf>
            <SvcLvl>
              <Cd>SEPA</Cd>
            </SvcLvl>
            <LclInstrm>
              <Cd>COR1</Cd>
            </LclInstrm>
            <SeqTp>FRST</SeqTp>
          </PmtTpInf>
          <ReqdColltnDt>2016-01-27</ReqdColltnDt>
          <Cdtr>
            <Nm>Test Account</Nm>
          </Cdtr>
          <CdtrAcct>
            <Id>
              <IBAN>AL90208110080000001039531801</IBAN>
            </Id>
          </CdtrAcct>
          <CdtrAgt>
            <FinInstnId>
              <Othr>
                <Id>NOTPROVIDED</Id>
              </Othr>
            </FinInstnId>
          </CdtrAgt>
          <ChrgBr>SLEV</ChrgBr>
          <CdtrSchmeId>
            <Id>
              <PrvtId>
                <Othr>
                  <Id>DE98ZZZ09999999999</Id>
                  <SchmeNm>
                    <Prtry>SEPA</Prtry>
                  </SchmeNm>
                </Othr>
              </PrvtId>
            </Id>
          </CdtrSchmeId>
          <DrctDbtTxInf>
            <PmtId>
              <EndToEndId>de340dc715540d7ba189d9daff3febf7</EndToEndId>
            </PmtId>
            <InstdAmt Ccy="EUR">1.23</InstdAmt>
            <DrctDbtTx>
              <MndtRltdInf>
                <MndtId>1123</MndtId>
                <DtOfSgntr>2016-01-25</DtOfSgntr>
              </MndtRltdInf>
            </DrctDbtTx>
            <DbtrAgt>
              <FinInstnId>
                <BIC>DABAIE2D</BIC>
              </FinInstnId>
            </DbtrAgt>
            <Dbtr>
              <Nm>Some person</Nm>
            </Dbtr>
            <DbtrAcct>
              <Id>
                <IBAN>AL90208110080000001039531801</IBAN>
              </Id>
            </DbtrAcct>
            <RmtInf>
              <Ustrd>Give me all your moneyz</Ustrd>
            </RmtInf>
          </DrctDbtTxInf>
        </PmtInf>
      </CstmrDrctDbtInitn>
    </Document>

  }
end


Fabricator(:debit, from: 'Box::Transaction') do
  eref { Fabricate.sequence(:debit) { |i| "debit-#{i}" } }
  type 'debit'
  payload { generate_payload }
  ebics_transaction_id 'B00U'
  status { %w[created file_upload funds_debited].sample }
  account_id 1
  order_type 'CDD'
  amount 123_45
  user_id 1
end
