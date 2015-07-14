import React from 'react';

class TextInput extends React.Component {
  render() {
    return(
      <div className="form-group">
        <label htmlFor={this.props.for}>{this.props.label}</label>
        <input type="text" id={this.props.for} ref={this.props.for} name={this.props.for} className="form-control" value={this.props.value} onChange={this.props.onChange} />
      </div>
    )
  }
}

export default TextInput;
