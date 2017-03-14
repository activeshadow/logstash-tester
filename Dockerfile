FROM logstash:5

RUN logstash-plugin install --development

ARG LST
ARG FILTER_CONFIG
ARG PATTERN_CONFIG
ARG FILTER_TESTS
ARG PATTERN_TESTS

ADD $LST/test       /test
ADD $FILTER_CONFIG  /test/spec/filter_config
ADD $PATTERN_CONFIG /etc/logstash/patterns
ADD $FILTER_TESTS   /test/spec/filter_data
ADD $PATTERN_TESTS  /test/spec/pattern_data

ADD bin/rspec /usr/local/bin/rspec
