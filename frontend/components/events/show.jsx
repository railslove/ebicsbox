import React, {Component} from 'react';
import Api from 'models/api';

class EventShow extends Component {
  constructor(props) {
    super(props);
    this.state = { event: null };
  }

  componentDidMount() {
    Api
      .fetchEvent(this.props.params.id)
      .then(event => this.setState({ event }))
  }

  render() {
    let event = this.state.event;
    if(!event) {
      return <div>Loading…</div>;
    }
    return(
      <div className="container">
        <div className="page-header">
          <h1>Event</h1>
        </div>

        <div className="well">
          <dl className="dl-horizontal">
            <dt>Type</dt>
            <dd>{event.type}</dd>
            <dt>Triggered</dt>
            <dd>{event.triggered_at}</dd>
            <dt>Webhook URL</dt>
            <dd>{event.webhook_url}</dd>
          </dl>
        </div>

        <table className="table table-hover">
          <thead>
            <tr>
              <th>Status</th>
              <th>Code</th>
              <th>When</th>
              <th>Took</th>
              <th>Response</th>
            </tr>
          </thead>
          <tbody>
            {event.webhook_deliveries.map(delivery => {
              let status;
              let code;
              if (delivery.response_status >= 100 && delivery.response_status < 300) {
                status = 'glyphicon glyphicon-ok text-success';
                code = 'label label-success';
              } else if (delivery.response_status == 0) {
                status = 'glyphicon glyphicon-remove text-danger';
                code = 'label label-default';
              } else {
                status = 'glyphicon glyphicon-remove text-danger';
                code = 'label label-danger';
              }
              return(
                <tr key={`delivery-${delivery.delivered_at}`}>
                  <td><span className={status} aria-hidden="true"></span></td>
                  <td><span className={code}>{delivery.response_status}</span></td>
                  <td>{delivery.delivered_at}</td>
                  <td>{delivery.response_time}ms</td>
                  <td>{delivery.response_body}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    )
  }
}

export default EventShow;
