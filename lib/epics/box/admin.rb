module Epics
  module Box
    class Admin < Sinatra::Base
      post '/migrate' do
        Sequel.extension :migration, :core_extensions
        Sequel::Migrator.run(DB, File.join( File.dirname(__FILE__),  '../../../migrations/'), use_transactions: true)
      end

      get '/accounts/new' do
        erb :new
      end

      get '/accounts/edit/:id' do
        @account = Epics::Box::Account.find(id: params[:id])
        erb :edit
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

      post '/accounts/:id' do
        @account = Epics::Box::Account.find(id: params[:id])
        if @account.update(params.slice("name", "bankname", "creditor_identifier", "callback_url", "host", "partner", "user", "url", "key", "passphrase", "mode", "ini_letter"))
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
