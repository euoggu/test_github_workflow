FROM redis/redisinsight:latest
USER 0
RUN rm -f /usr/src/app/redisinsight/api/node_modules/keytar/build/Release/keytar.node
USER 1000
