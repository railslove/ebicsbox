require("bootstrap-webpack");
require("./styles/custom.css");

var React = require('react');
import Navigation from './components/navigation.jsx';

class TestApp extends React.Component {
  render() {
    return(
      <div>
        <Navigation />
        <div className="container" role="main">
          <div className="row">
            <div className="col-xs-6">Hello</div>
            <div className="col-xs-6">World</div>
          </div>
        </div>
      </div>
    );
  }
}

React.render(
  <TestApp />,
  document.getElementById('application')
);
