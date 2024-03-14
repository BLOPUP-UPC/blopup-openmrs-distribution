#!/usr/bin/env bash
. scripts/functions.sh
NEW_RELIC_LICENSE_KEY=$1

sed -i '' "s/{{NEW_RELIC_LICENSE_KEY}}/$NEW_RELIC_LICENSE_KEY/g" docker/web/newrelic/newrelic.yml
sed -i '' "s/{{NEW_RELIC_LICENSE_KEY}}/$NEW_RELIC_LICENSE_KEY/g" docker/web/newrelic/newrelic-infra.yml
