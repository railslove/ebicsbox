import React from 'react';
import Api from '../models/api';
import TextInput from '../common/text_input';

class AccountForm extends React.Component {
  constructor(props) {
    super(props);

    // Set initial state
    this.state = { errorMessage: null, editing: false, account: {} };

    // Bind local methods
    this.createAndReturn = this.createAndReturn.bind(this);
    this.createAndContinue = this.createAndContinue.bind(this);
    this.updateAndReturn = this.updateAndReturn.bind(this);
    this.onError = this.onError.bind(this);
    this.onSuccess = this.onSuccess.bind(this);
    this.onContinue = this.onContinue.bind(this);
    this.handleChange = this.handleChange.bind(this);
  }

  componentWillMount() {
    if(this.props.params.id) {

      Api
        .fetchAccount(this.props.params.id)
        .then((data) => this.setState({ editing: true, account: data }));
    }
  }

  createAndReturn(e) {
    e.preventDefault();
    Api.createAccount(this.state.account)
      .then(this.onSuccess)
      .catch(this.onError);
  }

  createAndContinue(e) {
    e.preventDefault();
    Api.createAccount(this.state.account)
      .then(this.onContinue)
      .catch(this.onError);
  }

  updateAndReturn(e) {
    e.preventDefault();
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

  onContinue(responseData) {
    this.context.router.transitionTo('edit-account-ebics', { id: responseData.iban });
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

    var actionButtons;
    if(this.state.editing) {
      actionButtons = [
        <input type="submit" value="Save changes" onClick={this.updateAndReturn} className="btn btn-primary" />,
      ]
    } else {
      actionButtons = [
        <input type="submit" value="Create" onClick={this.createAndReturn} className="btn btn-primary" />,
        <button className="btn btn-default pull-right" onClick={this.createAndContinue}>Create and continue with EBICS data</button>
      ]
    }

    var data = this.state.account;
    return (
      <div className="container">
        <div className="row">
          <div className="col-sm-6">
            <p>{errorMessage}</p>
            <form>
              <h3>General Information</h3>
              <TextInput for="iban" label="IBAN" value={data.iban} onChange={this.handleChange} required={true} />
              <TextInput for="bic" label="BIC" value={data.bic} onChange={this.handleChange} />
              <TextInput for="bankname" label="Name of bank" value={data.bankname} onChange={this.handleChange} help="(Optional) Helps you to keep an overview of your accounts." />
              <TextInput for="creditor_identifier" label="Creditor ID" value={data.creditor_identifier} onChange={this.handleChange} help="Required to perform direct debits." />

              <hr />
              <h3>Box Configuration</h3>
              <TextInput for="name" label="Internal name" value={data.name} onChange={this.handleChange} help="Used across the administration area to reference a specific account." />
              <TextInput for="callback_url" label="WebHooks URL" value={data.callback_url} onChange={this.handleChange} help="The URL to which the box delivers update notifications." />

              {actionButtons}
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
