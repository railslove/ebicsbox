import React from 'react';
import $ from 'jquery';

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
          <small className="text-muted">{statement.iban}</small>
        </td>
        <td className="text-right">{formattedAmount}</td>
      </tr>
    )
  }
}

class AccountShow extends React.Component {
  constructor(props) {
    super()
    this.state = { data: [] };
    this.loadData();
  }

  loadData() {
    $.get('/DE10375700240868353400/statements', data => {
      this.setState({ data: data });
    });
  }

  render() {
    var statements = this.state.data;
    return (
      <div className="container">
        <div className="row">
          <div className="col-sm-4 col-md-3">
            Filter
          </div>
          <div className="col-sm-8 col-md-9">
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
