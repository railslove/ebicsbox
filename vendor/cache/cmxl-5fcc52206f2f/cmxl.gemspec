# -*- encoding: utf-8 -*-
# stub: cmxl 0.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "cmxl"
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Bumann"]
  s.date = "2016-02-16"
  s.description = "Cmxl provides an friendly, extensible and customizable parser for the MT940 bank statement format."
  s.email = ["michael@railslove.com"]
  s.files = [".gitignore", ".travis.yml", "CHANGELOG.mdown", "Gemfile", "LICENSE.txt", "README.md", "Rakefile", "cmxl.gemspec", "lib/cmxl.rb", "lib/cmxl/field.rb", "lib/cmxl/fields/account_balance.rb", "lib/cmxl/fields/account_identification.rb", "lib/cmxl/fields/available_balance.rb", "lib/cmxl/fields/closing_balance.rb", "lib/cmxl/fields/reference.rb", "lib/cmxl/fields/statement_details.rb", "lib/cmxl/fields/statement_line.rb", "lib/cmxl/fields/statement_number.rb", "lib/cmxl/statement.rb", "lib/cmxl/transaction.rb", "lib/cmxl/version.rb", "spec/field_spec.rb", "spec/fields/account_balance_spec.rb", "spec/fields/account_identification_spec.rb", "spec/fields/available_balance_spec.rb", "spec/fields/closing_balance_spec.rb", "spec/fields/reference_spec.rb", "spec/fields/statement_details_spec.rb", "spec/fields/statement_number_spec.rb", "spec/fields/statment_line_spec.rb", "spec/fields/unknown_spec.rb", "spec/fixtures/lines/account_balance_credit.txt", "spec/fixtures/lines/account_balance_debit.txt", "spec/fixtures/lines/account_identification_iban.txt", "spec/fixtures/lines/account_identification_legacy.txt", "spec/fixtures/lines/available_balance.txt", "spec/fixtures/lines/closing_balance.txt", "spec/fixtures/lines/reference.txt", "spec/fixtures/lines/statement_details.txt", "spec/fixtures/lines/statement_line.txt", "spec/fixtures/lines/statement_number.txt", "spec/fixtures/mt940-deutsche_bank.txt", "spec/fixtures/mt940-iso8859-1.txt", "spec/fixtures/mt940.txt", "spec/mt940_parsing_spec.rb", "spec/spec_helper.rb", "spec/support/fixtures.rb", "spec/transaction_spec.rb"]
  s.homepage = "https://github.com/railslove/cmxl"
  s.licenses = ["MIT"]
  s.post_install_message = "Thanks for using Cmxl - your friendly MT940 parser!\nWe hope we can make dealing with MT940 files a bit more fun. :) \nPlease create an issue on github if anything is not as expected.\n\n"
  s.rubygems_version = "2.4.8"
  s.summary = "Cmxl is your friendly MT940 bank statement parser"
  s.test_files = ["spec/field_spec.rb", "spec/fields/account_balance_spec.rb", "spec/fields/account_identification_spec.rb", "spec/fields/available_balance_spec.rb", "spec/fields/closing_balance_spec.rb", "spec/fields/reference_spec.rb", "spec/fields/statement_details_spec.rb", "spec/fields/statement_number_spec.rb", "spec/fields/statment_line_spec.rb", "spec/fields/unknown_spec.rb", "spec/fixtures/lines/account_balance_credit.txt", "spec/fixtures/lines/account_balance_debit.txt", "spec/fixtures/lines/account_identification_iban.txt", "spec/fixtures/lines/account_identification_legacy.txt", "spec/fixtures/lines/available_balance.txt", "spec/fixtures/lines/closing_balance.txt", "spec/fixtures/lines/reference.txt", "spec/fixtures/lines/statement_details.txt", "spec/fixtures/lines/statement_line.txt", "spec/fixtures/lines/statement_number.txt", "spec/fixtures/mt940-deutsche_bank.txt", "spec/fixtures/mt940-iso8859-1.txt", "spec/fixtures/mt940.txt", "spec/mt940_parsing_spec.rb", "spec/spec_helper.rb", "spec/support/fixtures.rb", "spec/transaction_spec.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>, ["~> 1.5"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, ["~> 3.0"])
      s.add_runtime_dependency(%q<rchardet19>, [">= 0"])
    else
      s.add_dependency(%q<bundler>, ["~> 1.5"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, ["~> 3.0"])
      s.add_dependency(%q<rchardet19>, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>, ["~> 1.5"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, ["~> 3.0"])
    s.add_dependency(%q<rchardet19>, [">= 0"])
  end
end
