# IPEM Toolbox — GNU Octave 10.3 container
#
# Build:
#   docker build -t ipem-toolbox:octave-10.3 .
#
# Smoke test:
#   docker run --rm ipem-toolbox:octave-10.3
#
# Interactive Octave with the toolbox on the path:
#   docker run --rm -it ipem-toolbox:octave-10.3 octave --no-gui

FROM docker.io/gnuoctave/octave:10.3.0

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    OCTAVE_HISTFILE=/tmp/octave-history \
    IPEM_ROOT=/opt/IPEMToolbox

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        libsndfile1 \
    && rm -rf /var/lib/apt/lists/*

# Install Octave Forge packages needed by the toolbox.
# control is a dependency of signal.
RUN octave --no-gui --quiet --eval "\
  pkg install -forge io; \
  pkg install -forge control; \
  pkg install -forge signal; \
  pkg list;"

WORKDIR ${IPEM_ROOT}

COPY AuditoryModel ${IPEM_ROOT}/AuditoryModel
COPY IPEMToolbox ${IPEM_ROOT}/IPEMToolbox
COPY tests ${IPEM_ROOT}/tests
COPY docker/octave-entrypoint.sh /usr/local/bin/octave-entrypoint.sh

RUN chmod +x /usr/local/bin/octave-entrypoint.sh \
    && mkdir -p ${IPEM_ROOT}/AuditoryModel/Octave_UNIX/Release \
    && mkdir -p ${IPEM_ROOT}/IPEMToolbox/Temp \
    && cd ${IPEM_ROOT}/AuditoryModel/Octave_UNIX \
    && make clean || true \
    && make \
    && make install \
    && test -f ${IPEM_ROOT}/IPEMToolbox/Common/IPEMProcessAuditoryModelSafe.mex

WORKDIR ${IPEM_ROOT}/IPEMToolbox

ENTRYPOINT ["/usr/local/bin/octave-entrypoint.sh"]
CMD ["smoke"]
