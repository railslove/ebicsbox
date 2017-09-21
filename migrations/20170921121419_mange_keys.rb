require "epics"

Sequel.migration do
  up do
    self[:subscribers].each do |sub|
      begin
        Epics::Client.new( StringIO.new(sub[:encryption_keys]) , ENV['PASSPHRASE'],'', '', '', '')
      rescue OpenSSL::Cipher::CipherError
        begin
          client = Epics::Client.new( StringIO.new(sub[:encryption_keys]) , 'aff072af1329d610b79f1105c899d280' ,'', '', '', '') rescue nil
          client.passphrase= ENV['PASSPHRASE']

          self[:subscribers].where(id: sub[:id]).update(encryption_keys: client.send(:dump_keys))
        rescue => e
          puts "something went wrong migrating #{sub[:id]}, #{e}"
        end
      end
    end
  end
end
