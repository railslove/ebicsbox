import React from 'react';
import Api from '../models/api';
import TextInput from '../common/text_input';

class AccountForm extends React.Component {
  constructor(props) {
    super(props);

    // Set initial state
    this.state = { errorMessage: null, editing: false, account: {} };

    // Bind local methods
    this.createAndContinue = this.createAndContinue.bind(this);
    this.updateAndContinue = this.updateAndContinue.bind(this);
    this.onError = this.onError.bind(this);
    this.onSuccess = this.onSuccess.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  componentWillMount() {
    if(this.props.params.id) {

      Api
        .fetchAccount(this.props.params.id)
        .then((data) => this.setState({ editing: true, account: data }));
    }
  }

  createAndContinue(e) {
    e.preventDefault();
    console.log(this.state.account);
    Api.createAccount(this.state.account)
      .then(this.onSuccess)
      .catch(this.onError);
  }

  updateAndContinue(e) {
    e.preventDefault();
    console.log(this.state.account);
    Api.updateAccount(this.props.params.id, this.state.account)
      .then(this.onSuccess)
      .catch(this.onError);
  }

  onError(errorMessage) {
    this.setState({ errorMessage: errorMessage.message });
  }

  onSuccess(responseData) {
    this.context.router.transitionTo('account-index');
  }

  handleChange(event) {
    var account = this.state.account;
    account[event.target.name] = event.target.value;
    this.setState({ account: account });
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

    var data = this.state.account;
    return (
      <div className="container">
        <div className="row">
          <div className="col-sm-6">
            <p>{errorMessage}</p>
            <form>
              <h3>General Information</h3>
              <TextInput for="bankname" label="Name of bank" value={data.bankname} onChange={this.handleChange} />
              <TextInput for="iban" label="IBAN" value={data.iban} onChange={this.handleChange} />
              <TextInput for="bic" label="BIC" value={data.bic} onChange={this.handleChange} />

              <hr />
              <h3>Box Configuartion</h3>
              <TextInput for="name" label="Internal name" value={data.name} onChange={this.handleChange} />
              <TextInput for="callback_url" label="Callback URL" value={data.callback_url} onChange={this.handleChange} />

              <hr />
              <h3>EBICS Setup</h3>
              <TextInput for="creditor_identifier" label="Creditor ID" value={data.creditor_identifier} onChange={this.handleChange} />
              <TextInput for="host" label="Host ID" value={data.host} onChange={this.handleChange} />
              <TextInput for="partner" label="Partner" value={data.partner} onChange={this.handleChange} />
              <TextInput for="user" label="User ID" value={data.user} onChange={this.handleChange} />
              <TextInput for="url" label="Url" value={data.url} onChange={this.handleChange} />
              <div className="form-group">
                <label htmlFor="mode">Mode</label>
                <select ref="mode" name="mode" className="form-control" value={data.mode} onChange={this.handleChange}>
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
