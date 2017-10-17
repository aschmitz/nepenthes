FROM ubuntu:xenial

RUN sed -i 's|deb-src|# deb-src|g' /etc/apt/sources.list && \
  echo "mysql-server-5.5 mysql-server/root_password password root" | debconf-set-selections && \
  echo "mysql-server-5.5 mysql-server/root_password_again password root" | debconf-set-selections && \
  apt-get update && apt-get install -y --no-install-recommends \
  tmux \
  build-essential \
  libfontconfig1 \
  libsqlite3-dev \
  libxslt1-dev \
  nmap \
  nikto \
  openssh-server \
  zlib1g-dev \
  redis-tools \
  ruby \
  ruby-dev \
  wget \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && adduser nepenthes --gecos "" --disabled-password

RUN cd /tmp && \
  wget -O phantomjs.tar.bz2 \
  https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
  sha256sum phantomjs.tar.bz2 | grep -q 86dd9a4bf4aee45f1a84c9f61cf1947c1d6dce9b9e8d2a907105da7852460d2f && \
  tar xjf phantomjs.tar.bz2 && \
  cp phantomjs-*/bin/phantomjs /bin/

# Install these before we copy all the files so we don't have to re-install all
# the gems/npm packages if just other files change.
COPY Gemfile /home/nepenthes/
RUN cd /home/nepenthes && \
  gem install --no-rdoc --no-ri bundler && \
  bundle install --without local

COPY . /home/nepenthes
RUN cd /home/nepenthes && \
  cp config/database.yml.example config/database.yml && \
  chmod 0777 log && \
  cp config/auth.yml.example config/auth.yml

USER nepenthes

ENTRYPOINT ["/home/nepenthes/script/docker-nepenthes-worker.sh"]
