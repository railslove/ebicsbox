class Api {
  // Account api

  static fetchAllAccounts() {
    return this.get(`/accounts`)
  }

  static fetchAccount(id) {
    return this.get(`/accounts/${id}`)
  }

  static createAccount(data) {
    return this.post('/accounts', data)
  }

  static updateAccount(id, data) {
    return this.put(`/accounts/${id}`, data)
  }

  static submitAccount(id) {
    return this.put(`/accounts/${id}/submit`)
  }

  static fetchAccountStatements(id) {
    return this.get(`/${id}/statements`)
  }

  static fetchEvents() {
    return this.get('/events')
  }

  static fetchEvent(id) {
    return this.get(`/events/${id}`)
  }

  // generic api methods

  static post(path, data) {
    return fetch(path, { method: 'post', credentials: 'include', headers: this.headers, body: JSON.stringify(data) })
      .then(this.status)
      .then(this.json);
  }

  static put(path, data) {
    return fetch(path, { method: 'put', credentials: 'include', headers: this.headers, body: JSON.stringify(data) })
      .then(this.status)
      .then(this.json);
  }

  static get(path) {
    return fetch(path, { method: 'get', credentials: 'include', headers: this.headers })
      .then(this.status)
      .then(this.json);
  }

  static status(response) {
    if (response.status >= 200 && response.status < 300) {
      return response
    }
    return response.json().then((data) => { throw new Error(data.error || data.message) });
  }

  static json(response) {
    return response.json()
  }
}

Api.headers = {
  'Accept': 'application/json',
  'Content-Type': 'application/json'
}

export default Api
