import React from 'react';
import Api from '../models/api';
import Info from '../common/info';

class AccountSubmit extends React.Component {
  constructor(props) {
    super(props);

    this.state = { account: {} }

    this.onSubmit = this.onSubmit.bind(this);
    this.printLetter = this.printLetter.bind(this);
  }

  componentWillMount() {
    Api
      .fetchAccount(this.props.params.id)
      .then((data) => { this.setState({ account: data })})
      .catch((error) => { alert(`Failed to load account (${error.message})`) })
  }

  onSubmit(e) {
    e.preventDefault();
    Api
      .submitAccount(this.props.params.id)
      .then((data) => { location.reload() })
      .catch((error) => { alert(`Failed to submit (${error.message})`) })
  }

  renderSubmit() {
    return(
      <div className="container">
        <div className="row">
          <div className="col-sm-6">
            <h3>Finish account setup</h3>
            <Info>
              Transmit encryption keys to your bank's servers and create an INI letter
              which you need to print and mail your bank manually!
            </Info>
            <button className="btn btn-primary" onClick={this.onSubmit}>Submit now!</button>
          </div>
        </div>
      </div>
    )
  }

  printLetter(e) {
    e.preventDefault();
    var printFrame = window.frames["iniletter-frame"];
    printFrame.focus();
    printFrame.print();
  }

  componentDidUpdate() {
    var printFrame = window.frames["iniletter-frame"];
    printFrame.document.write(`<body>${this.state.account.ini_letter}</body>`);
  }

  renderWaiting() {
    let submittedAt = new Date(this.state.account.submitted_at);
    let iframeContents = "data:text/html;charset=utf-8," + escape(this.state.account.ini_letter);
    return(
      <div className="container">
        <div className="row">
          <div className="col-sm-6">
            <h3>Finish account setup</h3>
            <Info type="warning">
              EBICS setup data has been submitted on {submittedAt.toLocaleDateString()}. Please print
              the following INI letter and send it to your bank, so they can activate your account.
              The EBICS::Box performs an activation check on a daily basis. As soon as the bank
              activates the EBICS account on their side, the system will update its status automatically.
            </Info>

            <iframe id="iniletter-frame" name="iniletter-frame" style={{width: '100%', border: '1px solid #ddd'}}>
              <p>Your browser does not support iframes.</p>
            </iframe>

            <button onClick={this.printLetter} className="btn btn-primary">print</button>
          </div>
        </div>
      </div>
    )
  }

  render() {
    switch(this.state.account.state) {
      case 'activated':
        this.context.router.transitionTo('account', { id: this.props.params.id });
        break;
      case 'submitted':
        return this.renderWaiting();
        break;
      case 'ready_to_submit':
        return this.renderSubmit();
      default:
        return(<div>Loading account data…</div>);
    }
  }
}
AccountSubmit.contextTypes = {
  router: React.PropTypes.func
}

export default AccountSubmit;
