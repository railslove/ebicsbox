var React = require('react');

class TestApp extends React.Component {
  render() {
    return <h1>Hello World!</h1>;
  }
}

React.render(
  <TestApp />,
  document.getElementById('application')
);
