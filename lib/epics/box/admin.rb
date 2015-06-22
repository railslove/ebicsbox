module Epics
  module Box
    class Admin < Sinatra::Base
      post '/migrate' do
        Sequel.extension :migration, :core_extensions
        Sequel::Migrator.run(DB, File.join( File.dirname(__FILE__),  '../../../migrations/'), use_transactions: true)
      end

      get '/accounts' do
        erb <<-FOO
          <form action="/admin/accounts" method="POST">
            <label for="name"/>Name</label>
            <input type="text" name="name" id="name" required/>
            <br/>
            <label for="iban"/>IBAN</label>
            <input type="text" name="iban" id="iban" required/>
            <br/>
            <label for="bic"/>BIC</label>
            <input type="text" name="bic" id="bic" required/>
            <br/>
            <label for="creditor_identifier"/>Creditor ID</label>
            <input type="text" name="creditor_identifier" id="creditor_identifier"/>
            <br/>
            <label for="callback_url"/>Callback URL</label>
            <input type="text" name="callback_url" id="callback_url" />
            <br/>
            <label for="passphrase"/>Passphrase</label>
            <input type="password" name="passphrase" id="passphrase" required/>
            <br/>
            <label for="host"/>Host ID</label>
            <input type="text" name="host" id="host" required/>
            <br/>
            <label for="partner"/>Partner ID</label>
            <input type="text" name="partner" id="partner" required/>
            <br/>
            <label for="user"/>User ID</label>
            <input type="text" name="user" id="user" required/>
            <br/>
            <label for="url"/>URL</label>
            <input type="text" name="url" id="url" required/>
            <br/>
            <label for="key"/>Key</label>
            <textarea name="key" id="key" required></textarea>
            <br/>
            <hr/>
            <input type="submit" value="Create"/>
          </form>
        FOO
      end

      post '/accounts' do
        if Epics::Box::Account.create(params.slice("name", "iban", "bic", "creditor_identifier", "callback_url", "passphrase", "host", "partner", "user", "url", "key"))
          "Yeah"
        else
           "Nooo"
        end
      end
    end
  end
end
