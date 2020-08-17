FROM registry.access.redhat.com/ubi8/ruby-25

ENV VERSION 0.0.1

LABEL io.k8s.description="volume-tester" \
  io.k8s.display-name="volume-tester v${VERSION}" \
  io.openshift.tags="test,qa" \
  name="volume-tester" \
  architecture="x86_64" \
  maintainer="github.com/FreedomBen"

COPY . /app

WORKDIR /app
USER root
RUN bundle install --local

USER default
EXPOSE 8080
CMD /app/app.rb
