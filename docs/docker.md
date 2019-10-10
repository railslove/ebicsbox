# ebicsbox 📦 on docker 🐳

## What's the ebicsbox?

To put it simple, the ebicsbox is a proxy for your bank's ebics interface to your application. Since the ebics standard is complex and not well readable, also a lot of security, handshaking and other things that are really hard, the ebicsbox provides you and your application with a handful of RESTful API endpoints to talk to your bank with simple JSON requests

## How to setup

- Make sure `docker` & `docker-compose` are setup and running.<br>
  This can be done via `(sudo) apt install docker-compose` which will automatically install docker if it's not already installed
- Create a new folder (e.g. `/home/ebicsbox`) for you ebicsbox and place the files in it
- If you decide to use the internal databases, create a subfolder `postgres` or similar. Make sure this path is in your backup-loop.
- Rename the `.env.example` to `.env` and update the content<br>
  If you decide to use the internal database make sure to provide the path you created in the step before.
- Rename the `.web.env.example` to `.web.env` and adjust the content - see the files for more comments on the configuration
- Start the cluster with `docker-compose up` and check for errors once everything is started. <br>
  If you decide to use the internal DBs, use `docker-compose -f docker-compose.yml -f docker-compose.with_db.yml up`

_Note:_ If you start the cluster for the first time, the worker and web will give out a lot of errors while the database is being setup. This should stop once the db is up and running.

## Check if everything is running

If you get `{"message":"Unauthorized access. Please provide a valid access token!"}` by running the following command, everything is working perfectly

```bash
  curl -XGET https://YOUR_VIRTUAL_HOST
```

You should be able to access the API-docs via `https://YOUR_VIRTUAL_HOST/docs`

## Retrieving the admins access token

```bash
  (sudo) docker exec -it ebicsbox_db_1 psql -U EBICSBOX_USER_NAME -W -d ebicsbox -c 'select access_token from users where id = 1'
```
