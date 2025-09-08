#!/bin/bash

file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"

	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

load_vars() {
	file_env "ADMIN_PASSWORD"
	file_env "SESSION_KEY"
}

install_adapt() {
	echo "No 'conf' dir found, running 'node install...'"

	# Gerar tenantname seguro e limpo
	tenantname=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')

	yes "" | node install --install Y \
		--authoringToolRepository https://github.com/adaptlearning/adapt_authoring.git \
		--frameworkRepository https://github.com/adaptlearning/adapt_framework.git \
		--frameworkRevision tags/v5.14.0 \
		--serverPort "${PORT}" \
		--serverName "${DOMAIN}" \
		--dbHost "${DB_HOST}" \
		--dbName "${DB_NAME}" \
		--dbPort "${DB_PORT}" \
		--useConnectionUri false \
		--dataRoot data \
		--sessionSecret "${SESSION_KEY}" \
		--useffmpeg Y \
		--useSmtp false \
		--masterTenantName "$tenantname" \
		--masterTenantDisplayName "$tenantname" \
		--suEmail "${ADMIN_EMAIL}" \
		--suPassword "${ADMIN_PASSWORD}" \
		--suRetypePassword "${ADMIN_PASSWORD}"
}

main() {
	set -eu

	load_vars

	if [ ! -d conf ]; then
		install_adapt
	fi
}

main

exec "$@"
