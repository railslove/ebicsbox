require 'nokogiri'

require_relative 'pain/credit_03'
require_relative 'pain/debit_02'

module Pain
  UnknownInput = Class.new(ArgumentError)
  def self.from_xml(raw_xml)
    doc = Nokogiri::XML(raw_xml).at_xpath("//xmlns:Document")
    case doc.namespace.href
    when "urn:iso:std:iso:20022:tech:xsd:pain.001.003.03"
      Pain::Credit03.new(doc)
    when "urn:iso:std:iso:20022:tech:xsd:pain.008.003.02"
      Pain::Debit02.new(doc)
    else
      fail UnknownInput, "Unknown xml file contents"
    end
  rescue Nokogiri::XML::XPath::SyntaxError => ex
    fail UnknownInput, "Invalid XML input"
  end
end
