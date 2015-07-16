import React from 'react';

class Info extends React.Component {
  render() {
    let cssClass = `alert alert-${this.props.type || 'info'}`;
    return (
      <div className={cssClass} role="alert">
        {this.props.children}
      </div>
    )
  }
}

export default Info;
