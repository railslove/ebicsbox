require("bootstrap-webpack");

import React from 'react';
import {Link} from 'react-router';

class Navigation extends React.Component {
  render() {
    return(
      <nav className="navbar navbar-inverse navbar-fixed-top">
        <div className="container">
          <div className="navbar-header">
            <button type="button" className="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
              <span className="sr-only">Toggle navigation</span>
              <span className="icon-bar"></span>
              <span className="icon-bar"></span>
              <span className="icon-bar"></span>
            </button>
            <a className="navbar-brand" href="#">EBICS::Box</a>
          </div>
          <div id="navbar" className="navbar-collapse collapse">
            <ul className="nav navbar-nav">
              <li><Link to="account-index">Accounts</Link></li>
              <li><Link to="events-index">Events</Link></li>
            </ul>
            <ul className="nav navbar-nav">
              <li><a href="http://docs.ebicsbox.apiary.io/">Documentation</a></li>
            </ul>
          </div>
        </div>
      </nav>
    );
  }
}

export default Navigation;
