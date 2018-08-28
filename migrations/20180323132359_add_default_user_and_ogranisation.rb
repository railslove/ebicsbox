Sequel.migration do
  up do
    self[:organizations].insert(name: 'Primary Organization', webhook_token: SecureRandom.hex(32)) unless self[:organizations].any?

    orga_id = self[:organizations].first[:id]
    self[:users].insert(organization_id: orga_id, name: 'Primary user', admin: true, access_token: SecureRandom.hex(32)) unless self[:users].any?
  end
end
