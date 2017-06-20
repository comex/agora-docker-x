FROM debian:latest
RUN apt-get -y update
#RUN echo "postfix postfix/mailname string list.agoranomic.org" | debconf-set-selections && \
#    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections
RUN apt-get install -y sudo sed python python-virtualenv python-dev build-essential postgresql libpq-dev swaks redis-server libxslt1-dev libjpeg62-turbo-dev zlib1g-dev
ADD groupserver-16.04.tar.gz /tmp/
ADD site.cfg /tmp/
RUN useradd -m -s /bin/bash user
RUN mv /tmp/groupserver-* /groupserver && \
    mv /tmp/site.cfg /groupserver/site.cfg && \
    chown -R user /groupserver
WORKDIR /groupserver
USER user
RUN virtualenv --no-site-packages .
RUN . ./bin/activate && pip install zc.buildout==2.5.0 setuptools==20.2.2
RUN . ./bin/activate && buildout -c buildout.cfg bootstrap
RUN . ./bin/activate && buildout -n install
RUN . ./bin/activate && buildout -n -c site.cfg install
# expensive stuff is done
RUN rmdir etc && ln -s /gs-persistent/groupserver-etc etc
USER root
RUN sed -ir -e "s@^.*max_prepared_transactions = .*@max_prepared_transactions = 10@" \
            -e "s@^.*data_directory = .*@data_directory = '/gs-persistent/postgres'@" \
            /etc/postgresql/9.?/main/postgresql.conf
