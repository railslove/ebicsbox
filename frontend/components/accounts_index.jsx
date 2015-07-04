import React from 'react';
import $ from 'jquery';
import {Link} from 'react-router';

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
    $.getJSON("/core/accounts", (result) => {
      this.setState({accounts: result});
    });
  }

  render() {
    console.log(this.state.accounts);
    var accounts = this.state.accounts.map(function(account, i) {
      var activated = (account.activated_at != undefined);
      var cssClass = activated ? 'panel-default' : 'panel-danger';
      var actionButton;
      if(activated) {
        actionButton = <Link to="account" params={{id: account.iban}} className="btn btn-primary btn-sm">Show details</Link>;
      } else {
        actionButton = <Link to="account" params={{id: account.iban}} className="btn btn-default btn-sm">Activate</Link>;
      }
      return (
        <li key={account.iban} className={`panel ${cssClass}`}>
          <div className="panel-heading">{account.name}</div>
          <div className="panel-body">
            <p>
              {account.iban}<br />
              {account.bankname}
            </p>
            {actionButton}
          </div>
        </li>
      );
    });

    return (
      <div className="container" role="main">
        <div className="row">
          <div className="col-sm-6 col-md-4">
            <p><Link to="new-account" className="btn btn-default">Add account</Link></p>
            <ul className="list-unstyled">
              {accounts}
            </ul>
          </div>
        </div>
      </div>
    );
  }
}

export default AccountsIndex;
