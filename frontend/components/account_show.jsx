import React from 'react';
import $ from 'jquery';
import Api from '../models/api';

class StatementRow extends React.Component {
  render() {
    var statement = this.props.statement;
    var amount = (statement.amount/100).toFixed(2)
    var cssClass = statement.debit ? 'text-danger' : 'text-success'
    var formattedAmount = <span className={cssClass}>EUR {amount}</span>;

    return(
      <tr key={`statement-${statement.statement.id}`}>
        <td className="no-wrap">{statement.date}</td>
        <td>
          <strong>{statement.name}</strong><br />
          <small className="text-muted">{statement.remittance_information}</small>
        </td>
        <td className="text-right">{formattedAmount}</td>
      </tr>
    )
  }
}

class AccountShow extends React.Component {
  constructor(props) {
    super(props);
    this.state = { account: null, statements: [] };
    this.loadData();
  }

  loadData() {
    var id = this.props.params.id;
    Api
      .fetchAccount(id)
      .then((data) => { this.setState({ account: data }) });

    Api.fetchAccountStatements(id)
      .then((data) => { this.setState({ statements: data }) });
  }

  render() {
    var account = this.state.account;
    var statements = this.state.statements;

    if(account == null) return <div>Loading…</div>;

    return (
      <div className="container">
      <div className="page-header">
        <h1>Account Details <small>{account.name}</small></h1>
      </div>
        <div className="row">
          <div className="col-sm-4 col-md-3">
            <dl>
              <dt>Bank</dt>
              <dd>{account.bank_name || 'unknown'}</dd>
              <dt>IBAN</dt>
              <dd>{account.iban}</dd>
              <dt>BIC</dt>
              <dd>{account.bic}</dd>
            </dl>
          </div>
          <div className="col-sm-8 col-md-9">
            <h3>Most recent statements</h3>
            <table className="table">
              <thead>
                <tr>
                  <th>Date</th>
                  <th>Name</th>
                  <th className="text-right">Amount</th>
                </tr>
              </thead>
              <tbody>
                {statements.map(statement => <StatementRow statement={statement} />)}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    );
  }
}

export default AccountShow;
