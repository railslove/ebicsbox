require("bootstrap-webpack");
require("./styles/custom.css");

var React = require('react');

import Navigation from './components/navigation';
import Dashboard from './components/dashboard';
import AccountsIndex from './components/accounts_index';
import AccountShow from './components/account_show';


var Router = require('react-router');
var Route = Router.Route;
var RouteHandler = Router.RouteHandler;

class App extends React.Component {
  render() {
    return(
      <div>
        <Navigation />
        <RouteHandler/>
      </div>
    );
  }
}

var routes = (
  <Route handler={App}>
    <Route path="/" handler={Dashboard} />
    <Route name="account" path="/accounts/:id" handler={AccountShow} />
    <Route path="/accounts" handler={AccountsIndex} />
  </Route>
);

Router.run(routes, Router.HashLocation, (Root) => {
  React.render(<Root/>, document.getElementById('application'));
});
