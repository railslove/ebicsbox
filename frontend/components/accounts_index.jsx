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
    $.getJSON("/core/accounts", function(result) {

      this.setState({accounts: result});

    }.bind(this));
  }

  render() {
    var accounts = this.state.accounts.map(function(account, i) {
      return (
        <tr key={account.iban}>
          <td>{account.iban}</td>
          <td>{account.bic}</td>
          <td>{account.bankname}</td>
          <td>
            <Link to="account" params={{id: account.iban}}>Show</Link>
          </td>
        </tr>
      );
    }, this)

    return (
      <div className="container" role="main">
        <div className="row">
          <table className="table table-hover">
            <thead>
              <tr>
                <th>IBAN</th>
                <th>BIC</th>
                <th>Bankname</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {accounts}
            </tbody>
          </table>
        </div>
      </div>
    );
  }
}

export default AccountsIndex;
