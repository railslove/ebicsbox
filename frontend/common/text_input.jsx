import React from 'react';

class TextInput extends React.Component {
  render() {
    var help;
    var helpId;
    if(this.props.help) {
      helpId = `help-for-${this.props.for}`;
      help = <span id={helpId} className="help-block">{this.props.help}</span>
    }

    return(
      <div className="form-group">
        <label htmlFor={this.props.for}>{this.props.label}</label>
        <input type="text" id={this.props.for} ref={this.props.for} name={this.props.for} required={this.props.required} className="form-control" value={this.props.value} onChange={this.props.onChange} aria-describedby={helpId} />
        {help}
      </div>
    )
  }
}

export default TextInput;
