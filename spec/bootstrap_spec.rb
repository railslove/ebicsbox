# frozen_string_literal: true

RSpec.describe Box do
  it "initializes the namespace" do
    expect(Box).to be_kind_of(Module)
  end

  describe ".configuration" do
    it "returns a configuration instance" do
      expect(described_class.configuration).to be_instance_of(Box::Configuration)
    end
  end

  describe ".logger" do
    it "returns a logger instance" do
      expect(described_class.logger).to be_instance_of(Logger)
    end
  end

  describe ".logger=" do
    it "allows to set the logger instance" do
      default_logger = described_class.logger

      logger = double("Logger")
      described_class.logger = logger
      expect(described_class.logger).to eq(logger)

      described_class.logger = default_logger
    end
  end
end
