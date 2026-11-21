# tribble-example-n8n

[n8n](https://n8n.io) in queue mode on tribble: a main process, workers and a webhook
processor from one image, with Postgres and Redis beside them.

The `Dockerfile` adds nothing to the upstream image but the settings every role shares.
`tribble.json` says which port the container listens on (5678) and how to check it is
healthy (`GET /healthz`, which all three roles answer).

## The apps

| app | start command | exposure | replicas |
| :-- | :-- | :-- | :-- |
| `n8n` | the image's own | public | 1 |
| `n8n-worker` | `n8n worker` | internal | 1 or more |
| `n8n-webhook` | `n8n webhook` | public or internal | 1 or more |
| Postgres | template | internal | 1 |
| Redis | template | internal | 1 |

All three n8n apps build from this repo and take the same variables.

## Variables

| variable | value |
| :-- | :-- |
| `N8N_ENCRYPTION_KEY` | a long random secret, **the same on all three apps** (a shared variable) |
| `DB_POSTGRESDB_HOST`, `DB_POSTGRESDB_PORT`, `DB_POSTGRESDB_DATABASE`, `DB_POSTGRESDB_USER`, `DB_POSTGRESDB_PASSWORD` | references to the Postgres app's variables |
| `QUEUE_BULL_REDIS_HOST`, `QUEUE_BULL_REDIS_PORT`, `QUEUE_BULL_REDIS_PASSWORD` | references to the Redis app's variables |
| `N8N_EDITOR_BASE_URL` | `https://<the main app's hostname>` |
| `N8N_WEBHOOK_URL` | the public address webhooks are called on (see below) |

n8n takes its database and Redis settings as separate values, not as one URL, so connect the
templates as pieces rather than as a URL.

## Webhooks

n8n expects a proxy in front that sends `/webhook/*` to the webhook processors and everything
else, `/webhook-test/*` included, to the main process, all on one hostname. tribble gives each
app its own hostname, so there are two ways to run it:

- **Main handles webhooks** (the simple one): `N8N_WEBHOOK_URL` is the main app's address, and
  `n8n-webhook` is left out or kept internal for the account's other apps to call.
- **A public webhook processor:** `N8N_WEBHOOK_URL` is `n8n-webhook`'s address. Production
  webhooks work; the editor's test webhooks do not, because their address is built from the
  same variable and the processor does not serve them.

## Notes

- A worker has no web server of its own. `QUEUE_HEALTH_CHECK_ACTIVE` (set in the image) makes
  it answer `/healthz` on 5678 so the platform can tell it is up.
- Nothing is kept on the container's disk that matters: workflows and credentials are in
  Postgres, encrypted with `N8N_ENCRYPTION_KEY`. So the n8n apps need no volume and can run
  several replicas.
- Code nodes run in n8n's built-in task runner, inside the same container.
  They may use Node's `tls` module (`NODE_FUNCTION_ALLOW_BUILTIN` in the image) and no other
  built-in, which is what a workflow needs to read a site's certificate.
- To upgrade, change the tag in the `Dockerfile` and build all three apps.
