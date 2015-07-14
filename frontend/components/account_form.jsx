import React from 'react';
import Api from '../models/api';
import TextInput from '../common/text_input';

class AccountForm extends React.Component {
  constructor(props) {
    super(props);

    // Set initial state
    this.state = { errorMessage: null, editing: false, account: {}, continueToEbics: false, running: false };

    // Bind local methods
    this.create = this.create.bind(this);
    this.updateAndReturn = this.updateAndReturn.bind(this);
    this.onError = this.onError.bind(this);
    this.onSuccess = this.onSuccess.bind(this);
    this.handleChange = this.handleChange.bind(this);
    this.changeReturn = this.changeReturn.bind(this);
  }

  componentWillMount() {
    if(this.props.params.id) {

      Api
        .fetchAccount(this.props.params.id)
        .then((data) => this.setState({ editing: true, account: data }));
    }
  }

  create(e) {
    e.preventDefault();
    this.setState({ running: true });
    Api.createAccount(this.state.account)
      .then(this.onSuccess)
      .catch(this.onError);
  }

  updateAndReturn(e) {
    e.preventDefault();
    this.setState({ running: true });
    Api.updateAccount(this.props.params.id, this.state.account)
      .then(this.onSuccess)
      .catch(this.onError);
  }

  onError(errorMessage) {
    this.setState({ errorMessage: errorMessage.message, running: false });
  }

  onSuccess(responseData) {
    if(this.state.continueToEbics) {
      this.context.router.transitionTo('edit-account-ebics', { id: responseData.iban });
    } else {
      this.context.router.transitionTo('account-index');
    }
  }

  handleChange(event) {
    var account = this.state.account;
    account[event.target.name] = event.target.value;
    this.setState({ account: account });
  }

  changeReturn(event) {
    this.setState({ continueToEbics: event.target.value == '1' });
  }

  render() {
    var data = this.state.account;
    var header = this.state.editing ? `Edit account „${data.name}”` : 'Add a new account';

    var errorMessage;
    if(this.state.errorMessage) {
      errorMessage = <div className="alert alert-danger" role="alert">{this.state.errorMessage}</div>;
    }

    var continueBlock;
    if(!this.state.editing) {
      continueBlock = (
        <div className="form-group">
          <label>Did you already receive your EBICS credentials?</label>
          <br/>
          <label className="radio-inline">
            <input type="radio" name="inlineRadioOptions" value="0" checked={this.state.continueToEbics == false} onChange={this.changeReturn} /> no
          </label>
          <label className="radio-inline">
            <input type="radio" name="inlineRadioOptions" value="1" checked={this.state.continueToEbics == true} onChange={this.changeReturn} /> yes
          </label>
        </div>
      )
    }

    var actionButtons;
    if(this.state.editing) {
      actionButtons = <input type="submit" value="Save changes" onClick={this.updateAndReturn} className="btn btn-primary" disabled={this.state.running} />;
    } else {
      var buttonText = this.state.continueToEbics ? "Save and enter EBICS data" : "Save and return"
      actionButtons = <input type="submit" value={buttonText} className="btn btn-primary" onClick={this.create} disabled={this.state.running} />;
    }
    return (
      <div className="container">
        <div className="page-header"><h1>{header}</h1></div>
        <div className="row">
          <div className="col-sm-6">
            <p>{errorMessage}</p>
            <form>
              <TextInput for="name" label="Internal name" value={data.name} onChange={this.handleChange} help="Used across the administration area to reference a specific account." />
              <TextInput for="iban" label="IBAN" value={data.iban} onChange={this.handleChange} required={true} />
              <TextInput for="bic" label="BIC" value={data.bic} onChange={this.handleChange} />
              <TextInput for="bankname" label="Name of bank" value={data.bankname} onChange={this.handleChange} />
              <TextInput for="creditor_identifier" label="Creditor ID" value={data.creditor_identifier} onChange={this.handleChange} help="(Optional) Add if you want to perform direct debits." />
              <TextInput for="callback_url" label="WebHooks URL" value={data.callback_url} onChange={this.handleChange} help="The URL to which the box delivers update notifications." />
              {continueBlock}
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
