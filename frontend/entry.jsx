require("bootstrap-webpack");
require("./styles/custom.css");

var React = require('react');

import Navigation from './components/navigation';
import Dashboard from './components/dashboard';

import AccountsIndex from './components/accounts_index';
import AccountShow from './components/account_show';
import AccountForm from './components/account_form';
import AccountEbics from './components/account_ebics';
import AccountSubmit from './components/account_submit';

import EventsIndex from './components/events/index';
import EventShow from './components/events/show';

var Router = require('react-router');
var {Route, Redirect} = Router;
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
    <Redirect from="/" to="account-index" />
    <Route name="new-account" path="/accounts/new" handler={AccountForm} />
    <Route name="edit-account" path="/accounts/:id/edit" handler={AccountForm} />
    <Route name="edit-account-ebics" path="/accounts/:id/edit/ebics" handler={AccountEbics} />
    <Route name="submit-account" path="/accounts/:id/submit" handler={AccountSubmit} />
    <Route name="account" path="/accounts/:id" handler={AccountShow} />
    <Route name="account-index" path="/accounts" handler={AccountsIndex} />
    <Route name="event" path="/events/:id" handler={EventShow} />
    <Route name="events-index" path="/events" handler={EventsIndex} />
  </Route>
);

Router.run(routes, Router.HashLocation, (Root) => {
  React.render(<Root/>, document.getElementById('application'));
});
