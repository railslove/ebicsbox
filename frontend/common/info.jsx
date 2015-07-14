import React from 'react';

class Info extends React.Component {
  render() {
    return (
      <div className="alert alert-info"  role="alert">
        {this.props.children}
      </div>
    )
  }
}

export default Info;
