FROM alpine:latest

RUN apk add --no-cache samba bash tzdata && \
    rm -f /etc/samba/smb.conf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 139 445

HEALTHCHECK --interval=30s --timeout=5s CMD smbclient -L localhost -N || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
