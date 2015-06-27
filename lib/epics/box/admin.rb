module Epics
  module Box
    class Admin < Sinatra::Base
      post '/migrate' do
        Sequel.extension :migration, :core_extensions
        Sequel::Migrator.run(DB, File.join( File.dirname(__FILE__),  '../../../migrations/'), use_transactions: true)
      end

      get '/accounts/new' do
        <<-FOO
          <form action="/admin/accounts" method="POST">
            <label for="name"/>Name</label>
            <input type="text" name="name" id="name" required/>
            <br/>
            <label for="bankname"/>Bankname</label>
            <input type="text" name="bankename" id="bankname" required/>
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
            <label for="mode"/>Mode</label>
            <select name="mode" id="mode">
              <option>File</option>
              <option>Ebics</option>
            </select>
            <br/>
            <hr/>
            <input type="submit" value="Create"/>
          </form>
        FOO
      end

      post '/accounts/setup/:id' do
        @account = Epics::Box::Account.find(id: params[:id])
        if @account.ini_letter.nil? || params[:reset]
          @account.setup!
        end
        redirect to("/accounts/ini_letter/#{@account.id}")
      end

      get '/accounts/setup/:id' do
        @account = Epics::Box::Account.find(id: params[:id])

        erb :setup
      end

      post '/accounts/activate/:id' do
        @account = Epics::Box::Account.find(id: params[:id])
        # TODO: handle the error case
        @account.activate!
        redirect to("/accounts")
      end

      get '/accounts/ini_letter/:id' do
        @account = Epics::Box::Account.find(id: params[:id])
        if @account.ini_letter
          erb :ini_letter
        else
          redirect to("/accounts")
        end
      end

      get '/accounts/ini_letter/:id/letter' do
        @account = Epics::Box::Account.find(id: params[:id])
        @account.ini_letter #render the ini lette
      end

      post '/accounts' do
        if Epics::Box::Account.create(params.slice("name", "bankname", "iban", "bic", "creditor_identifier", "callback_url", "host", "partner", "user", "url", "mode"))
          redirect to("/accounts")
        else
           "Nooo"
        end
      end

      get '/accounts' do
        @accounts = Epics::Box::Account.all

        erb :accounts
      end
    end
  end
end
