FROM eclipse-mosquitto

COPY docker-entrypoint.sh /

COPY $MOSQUITTO_PASSWORDFILE /

ENTRYPOINT ["sh", "./docker-entrypoint.sh"]

CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
