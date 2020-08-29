FROM eclipse-mosquitto

COPY docker-entrypoint.sh /

COPY password.txt /

ENTRYPOINT ["sh", "./docker-entrypoint.sh"]

CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
