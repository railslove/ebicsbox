import React from 'react';
import Api from '../models/api';

class AccountForm extends React.Component {
  constructor() {
    super();

    // Set initial state
    this.state = { errorMessage: null };

    // Bind local methods
    this.saveAndContinue = this.saveAndContinue.bind(this);
    this.onError = this.onError.bind(this);
    this.onSuccess = this.onSuccess.bind(this);
  }

  saveAndContinue(e) {
    e.preventDefault();

    var formData = {
      bankname: this.refs.bankname.getDOMNode().value,
      iban: this.refs.iban.getDOMNode().value,
      bic: this.refs.bic.getDOMNode().value,
      name: this.refs.name.getDOMNode().value,
      callback_url: this.refs.callback_url.getDOMNode().value,
      creditor_identifier: this.refs.creditor_identifier.getDOMNode().value,
      host: this.refs.host.getDOMNode().value,
      partner: this.refs.partner.getDOMNode().value,
      user: this.refs.user.getDOMNode().value,
      url: this.refs.url.getDOMNode().value,
      mode: this.refs.mode.getDOMNode().value,
    };

    Api.post('/accounts', formData)
      .then(this.onSuccess)
      .catch(this.onError);
  }

  onError(errorMessage) {
    this.setState({ errorMessage: errorMessage.message });
  }

  onSuccess(responseData) {
    this.context.router.transitionTo('account-index');
  }

  render() {
    var errorMessage;
    if(this.state.errorMessage) {
      errorMessage = <div className="alert alert-danger" role="alert">{this.state.errorMessage}</div>;
    }
    return (
      <div className="container">
        <div className="row">
          <div className="col-sm-6">
            <p>{errorMessage}</p>
            <form>
              <h3>General Information</h3>
              <div className="form-group">
                <label htmlFor="bankname">Name of bank</label>
                <input type="text" ref="bankname" placeholder="Name of bank" required className="form-control" />
              </div>

              <div className="form-group">
                <label htmlFor="iban">IBAN</label>
                <input type="text" ref="iban" required className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="bic">BIC</label>
                <input type="text" ref="bic" required className="form-control" />
              </div>

              <hr />
              <h3>Box Configuartion</h3>
              <div className="form-group">
                <label htmlFor="name">Name</label>
                <input type="text" ref="name" placeholder="Descriptive internal name" className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="callback_url">Callback URL</label>
                <input type="text" ref="callback_url" placeholder="Endpoint to receive webhooks" className="form-control" />
              </div>

              <hr />
              <h3>EBICS Setup</h3>
              <div className="form-group">
                <label htmlFor="creditor_identifier">Creditor ID</label>
                <input type="text" ref="creditor_identifier" className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="host">Host ID</label>
                <input type="text" ref="host" className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="partner">Partner ID</label>
                <input type="text" ref="partner" className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="user">User ID</label>
                <input type="text" ref="user" className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="url">URL</label>
                <input type="text" ref="url" className="form-control" />
              </div>
              <div className="form-group">
                <label htmlFor="mode">Mode</label>
                <select ref="mode" id="mode" className="form-control">
                  <option>File</option>
                  <option>Epics::Client</option>
                </select>
              </div>
              <input type="submit" value="Create" onClick={this.saveAndContinue} className="btn btn-primary" />
            </form>
          </div>
        </div>
      </div>
    );
  }
}

AccountForm.contextTypes = {
  router: React.PropTypes.func
};

export default AccountForm;
