ARG EMQX_VERSION
FROM emqx/emqx:${EMQX_VERSION}

ARG EMQX_DIR=/opt/emqx
ADD acl.conf ${EMQX_DIR}/etc/acl.conf

EXPOSE 1883
