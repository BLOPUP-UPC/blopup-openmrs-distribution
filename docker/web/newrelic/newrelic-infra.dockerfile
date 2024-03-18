FROM newrelic/infrastructure:latest
ADD newrelic/newrelic-infra.yml /etc/newrelic-infra.yml
ADD newrelic/logging.d /etc/newrelic-infra/logging.d