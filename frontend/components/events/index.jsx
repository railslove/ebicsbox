import React, {Component} from 'react';
import Api from 'models/api';
import {Link} from 'react-router';

class EventRow extends Component {
  render() {
    let event = this.props.event;
    var cssClass = (event.webhook_status == 'failed') ? 'danger' : '';
    var triggeredAt = new Date(event.triggered_at);
    return(
      <tr key={`event-${event.id}`} className={cssClass}>
        <td>{triggeredAt.toLocaleDateString()}{' '}{triggeredAt.toLocaleTimeString()}</td>
        <td><Link to="account" params={{id: event.account.iban}}>{event.account.name}</Link></td>
        <td>{event.type}</td>
        <td>{event.webhook_status}</td>
        <td>{event.webhook_retries}</td>
        <td><Link to="event" params={{id: event.id}} className="btn btn-xs btn-default">Details</Link></td>
      </tr>
    )
  }
}

class EventsIndex extends Component {
  constructor(props) {
    super(props);
    this.state = { events: [] };
  }
  componentDidMount() {
    Api
      .fetchEvents()
      .then(events => this.setState({ events }))
  }
  render() {
    return(
      <div className="container">
        <div className="page-header">
          <h1>Events</h1>
        </div>
        <table className="table table-hover">
          <thead>
            <tr>
              <th>When</th>
              <th>Account</th>
              <th>Type</th>
              <th>Webhook Status</th>
              <th>Retries</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {this.state.events.map(event => <EventRow event={event} />)}
          </tbody>
        </table>
      </div>
    )
  }
}

export default EventsIndex;
