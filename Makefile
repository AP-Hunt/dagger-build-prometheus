DAGGER_BINARY := $(shell which dagger 2>/dev/null)

PROMETHEUS_VERSION := main
GOLANG_VERSION := 1.18

dagger:
ifndef DAGGER_BINARY
	echo "Installing dagger"
else
	echo "Not installing dagger"
endif

run: dagger prometheus/
	@dagger project init
	@dagger do build -l debug --log-format tty

prometheus/:
	@git clone https://github.com/prometheus/prometheus.git
	@cd prometheus
	@git checkout "${PROMETHEUS_VERSION}"