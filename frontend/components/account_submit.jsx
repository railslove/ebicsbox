import React from 'react';
import Info from '../common/info';

class AccountSubmit extends React.Component {
  render() {
    return(
      <div className="container">
        <div className="row">
          <div className="col-sm-6">
            <h3>Finish account setup</h3>
            <Info>
              Transmit encryption keys to your bank's servers and create an INI letter
              which you need to print and mail your bank manually!
            </Info>
            <button className="btn btn-primary">Submit now!</button>
          </div>
        </div>
      </div>
    )
  }
}

export default AccountSubmit;
