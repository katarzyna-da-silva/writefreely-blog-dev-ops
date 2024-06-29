FROM ubuntu:latest

# DEPENDENCIES

RUN mkdir -p /app /var/www/writefreely /tmp/writefreely-0.15.0 \
    && apt-get update \
    && apt-get install -y wget apache2 mariadb-client tar \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# install writefreely 
RUN wget https://github.com/writeas/writefreely/releases/download/v0.15.0/writefreely_0.15.0_linux_amd64.tar.gz \
    && tar -xzf writefreely_0.15.0_linux_amd64.tar.gz -C /tmp/writefreely-0.15.0  \
    && mv /tmp/writefreely-0.15.0/writefreely /app/writefreely \
    && chmod +x /app/writefreely \
    && rm writefreely_0.15.0_linux_amd64.tar.gz

RUN ls -l /app

# 
COPY --chown=root:root --chmod=+x www/writefreely /app/writefreely

COPY www/writefreely /app/writefreely

COPY www/writefreely/config.ini /app/writefreely/config.ini

WORKDIR /app/writefreely

USER root

# si il existe app/writefreely - execute
RUN if [ -f /app/writefreely/writefreely ]; then \
        chmod +x /app/writefreely/writefreely && \
        ls -l /app/writefreely && \
        /app/writefreely/writefreely --gen-keys && \
 	mkdir -p /var/www/writefreely/keys/ && \
        cp /app/writefreely/keys/*.aes256 /var/www/writefreely/keys/ && \
        cp /app/writefreely/config.ini /var/www/writefreely/config.ini && \
        chmod 644 /var/www/writefreely/config.ini; \
    else \
        echo "File /app/writefreely not found or not executable"; \
    fi


COPY /www/writefreely/config.ini /var/www/writefreely/config.ini

# copie config apache
COPY writefreely.conf /etc/apache2/sites-available/writefreely.conf


# entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# output  entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# pour  WriteFreely
CMD ["/app/writefreely/writefreely"]

# Expose port 80
EXPOSE 8080
