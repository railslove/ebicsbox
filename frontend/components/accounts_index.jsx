import React from 'react';
import {Link} from 'react-router';
import Api from '../models/api';

class AccountsIndex extends React.Component {

  constructor(props) {
    super(props);
    this.state = {accounts: [{
      iban: '',
      bic: '',
      bankname: ''
    }]};
  }

  componentDidMount() {
    Api
      .fetchAllAccounts()
      .then((accounts) => this.setState({ accounts: accounts }))
      .catch((error) => alert(`Could not load account! (${error.message})`))
  }

  render() {
    var accounts = this.state.accounts.map(function(account, i) {
      var activated = (account.activated_at != undefined);
      var cssClass = activated ? 'panel-default' : 'panel-danger';
      var actionButton;
      if(activated) {
        actionButton = <Link to="account" params={{id: account.iban}} className="btn btn-primary btn-sm">Show details</Link>;
      } else {
        actionButton = <Link to="edit-account-ebics" params={{id: account.iban}} className="btn btn-default btn-sm">Setup</Link>;
      }
      return (
        <li key={account.iban} className="col-xs-12 col-sm-6 col-lg-4">
          <div className={`panel ${cssClass}`}>
            <div className="panel-heading">{account.name || <em className="text-muted">No account name</em>}</div>
            <div className="panel-body">
              <p>
                {account.iban}<br />
                {account.bankname || <em className="text-muted">No bank name</em>}
              </p>
              {actionButton}
              {' '}
              <Link to="edit-account" params={{id: account.iban}} className="btn btn-sm">Edit</Link>
            </div>
          </div>
        </li>
      );
    });

    return (
      <div className="container" role="main">
        <p><Link to="new-account" className="btn btn-default">Add account</Link></p>
        <ul className="list-unstyled row">
          {accounts}
        </ul>
      </div>
    );
  }
}

export default AccountsIndex;
