import React from 'react';
import Api from '../models/api';

import TextInput from '../common/text_input';
import Info from '../common/info';

class AccountEbics extends React.Component {
  constructor(props) {
    super(props);

    this.state = { errorMessage: null, loading: true, account: {} };

    this.cancel = this.cancel.bind(this);
  }

  componentWillMount() {
    if(this.props.params.id) {
      Api
        .fetchAccount(this.props.params.id)
        .then((data) => this.setState({ loading: false, account: data }));
    }
  }

  renderLoading() {
    return(
      <div>Loading account data…</div>
    )
  }

  cancel(e) {
    e.preventDefault();
    this.context.router.transitionTo('account-index');
  }

  renderForm() {
    var data = this.state.account;
    var errorMessage = this.state.errorMessage;
    return(
      <div className="container">
        <div className="row">
          <div className="col-sm-6">
            <h3>EBICS Setup for „{data.name}” <small>IBAN: {data.iban}</small></h3>
            <form>
              <p>{errorMessage}</p>
              <Info>Please enter the EBICS credentials as provided by your bank.</Info>
              <TextInput for="user" label="User ID" value={data.user} onChange={this.handleChange} />
              <TextInput for="partner" label="Partner ID" value={data.partner} onChange={this.handleChange} />
              <TextInput for="host" label="Host ID" value={data.host} onChange={this.handleChange} help="Unique identifier for your bank" />
              <TextInput for="url" label="Server Url" value={data.url} onChange={this.handleChange} help="Your bank's EBICS server URL" />
              <input type="submit" className="btn btn-primary" value="Save and continue" />
              {' or '}
              <a href="#" onClick={this.cancel}>cancel</a>
            </form>
          </div>
        </div>
      </div>
    );
  }

  render() {
    if(this.state.loading) {
      return this.renderLoading();
    } else {
      return this.renderForm();
    }
  }
}

AccountEbics.contextTypes = {
  router: React.PropTypes.func
};

export default AccountEbics;
