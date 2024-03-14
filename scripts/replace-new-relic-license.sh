#!/usr/bin/env bash
NEW_RELIC_LICENSE_KEY=$1

sed -i'' -e "s/{{NEW_RELIC_LICENSE_KEY}}/$NEW_RELIC_LICENSE_KEY/g" docker/web/newrelic/newrelic.yml
sed -i'' -e "s/{{NEW_RELIC_LICENSE_KEY}}/$NEW_RELIC_LICENSE_KEY/g" docker/web/newrelic/newrelic-infra.yml
