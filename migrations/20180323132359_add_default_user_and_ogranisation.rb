Sequel.migration do
  up do
    self[:organizations].insert(name: 'Primary Organization', webhook_token: SecureRandom.hex(32)) unless self[:organizations].any?

    if self[:users].empty?
      orga_id = self[:organizations].first[:id]
      token = SecureRandom.hex(32)
      self[:users].insert(organization_id: orga_id, name: 'Primary user', admin: true, access_token: token)
    end
  end
end
