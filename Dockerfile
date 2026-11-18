# n8n in queue mode, for a platform that runs one container per app.
#
# One image, three apps. The app's start command picks the role:
#   (none)        the main process: editor, API, test webhooks
#   n8n worker    runs executions taken from the Redis queue
#   n8n webhook   receives production webhooks
FROM n8nio/n8n:2.48.5

# What is the same for every role and every deployment. Everything that differs
# (database, Redis, the encryption key, public URLs) is set on the app.
ENV EXECUTIONS_MODE=queue \
    DB_TYPE=postgresdb \
    OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS=true \
    QUEUE_HEALTH_CHECK_ACTIVE=true \
    N8N_PROXY_HOPS=1
