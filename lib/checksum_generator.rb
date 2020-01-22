class ChecksumGenerator
  class << self
    def from_payload(payload)
      payload = payload.flatten.compact.map(&:to_s).reject(&:empty?).join if payload.is_a?(Array)
      Digest::SHA2.hexdigest(payload).to_s
    end
  end
end