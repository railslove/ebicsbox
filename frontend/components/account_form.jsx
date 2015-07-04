import React from 'react';

class AccountForm extends React.Component {
  render() {
    return (
      <div className="container">
        <div className="row">
          <div className="col-sm-6">
            <form>
              <h3>General Information</h3>
              <div className="form-group">
                <label for="bankname">Name of bank</label>
                <input type="text" name="bankname" placeholder="Name of bank" id="bankname" required  className="form-control" />
              </div>

              <div className="form-group">
                <label for="iban">IBAN</label>
                <input type="text" name="iban" id="iban" required  className="form-control" />
              </div>
              <div className="form-group">
                <label for="bic">BIC</label>
                <input type="text" name="bic" id="bic" required  className="form-control" />
              </div>

              <hr />
              <h3>Box Configuartion</h3>
              <div className="form-group">
                <label for="name">Name</label>
                <input type="text" name="name" placeholder="Descriptive internal name" id="name" required  className="form-control" />
              </div>
              <div className="form-group">
                <label for="callback_url">Callback URL</label>
                <input type="text" name="callback_url" placeholder="Endpoint to receive webhooks" id="callback_url" required  className="form-control" />
              </div>

              <hr />
              <h3>EBICS Setup</h3>
              <div className="form-group">
                <label for="creditor_identifier">Creditor ID</label>
                <input type="text" name="creditor_identifier" id="creditor_identifier" required  className="form-control" />
              </div>
              <div className="form-group">
                <label for="host">Host ID</label>
                <input type="text" name="host" id="host" required  className="form-control" />
              </div>
              <div className="form-group">
                <label for="partner">Partner ID</label>
                <input type="text" name="partner" id="partner" required  className="form-control" />
              </div>
              <div className="form-group">
                <label for="user">User ID</label>
                <input type="text" name="user" id="user" required  className="form-control" />
              </div>
              <div className="form-group">
                <label for="url">URL</label>
                <input type="text" name="url" id="url" required  className="form-control" />
              </div>
              <div className="form-group">
                <label for="mode">Mode</label>
                <select name="mode" id="mode" className="form-control">
                  <option>File</option>
                  <option>Epics::Client</option>
                </select>
              </div>
              <input type="submit" value="Create" className="btn btn-primary" />
            </form>
          </div>
        </div>
      </div>
    );
  }
}

export default AccountForm;
