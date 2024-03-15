FROM newrelic/infrastructure:latest
ADD docker/web/newrelic/newrelic-infra.yml /etc/newrelic-infra.yml
ADD docker/web/newrelic/logging.d /etc/newrelic-infra/logging.d