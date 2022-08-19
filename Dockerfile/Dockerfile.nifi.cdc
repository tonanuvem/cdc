FROM apache/nifi

COPY ./templates/* /opt/nifi/nifi-current/conf/templates/
