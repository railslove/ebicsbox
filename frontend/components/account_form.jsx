import React from 'react';
import Api from '../models/api';

class AccountForm extends React.Component {
  constructor(props) {
    super(props);

    // Set initial state
    this.state = { errorMessage: null, editing: false };

    // Bind local methods
    this.createAndContinue = this.createAndContinue.bind(this);
    this.updateAndContinue = this.updateAndContinue.bind(this);
    this.onError = this.onError.bind(this);
    this.onSuccess = this.onSuccess.bind(this);
    this.setupForm = this.setupForm.bind(this);
    this.formData = this.formData.bind(this);
  }

  componentWillMount() {
    if(this.props.params && this.props.params.id) {
      Api
        .fetchAccount(this.props.params.id)
        .then(this.setupForm);
    }
  }

  setupForm(data) {
    this.refs.bankname.getDOMNode().value = data.bankname;
    this.refs.iban.getDOMNode().value = data.iban;
    this.refs.bic.getDOMNode().value = data.bic;

    this.refs.name.getDOMNode().value = data.name;
    this.refs.callback_url.getDOMNode().value = data.callback_url;

    this.refs.creditor_identifier.getDOMNode().value = data.creditor_identifier;
    this.refs.host.getDOMNode().value = data.host;
    this.refs.partner.getDOMNode().value = data.partner;
    this.refs.user.getDOMNode().value = data.user;
    this.refs.url.getDOMNode().value = data.url;
    this.refs.mode.getDOMNode().value = data.mode;

    this.setState({ editing: true });
  }

  formData() {
    return {
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
    }
  }

  createAndContinue(e) {
    e.preventDefault();

    Api.createAccount(this.formData())
      .then(this.onSuccess)
      .catch(this.onError);
  }

  updateAndContinue(e) {
    e.preventDefault();
    Api.updateAccount(this.props.params.id, this.formData())
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

    var actionButton;
    if(this.state.editing) {
      actionButton = <input type="submit" value="Save changes" onClick={this.updateAndContinue} className="btn btn-primary" />;
    } else {
      actionButton = <input type="submit" value="Create" onClick={this.createAndContinue} className="btn btn-primary" />;
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
              {actionButton}
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
