FROM ruby:2.7-slim

ENV DRADIS_VERSION=main \
	RAILS_ENV=production \
    APT_ARGS="-y --no-install-recommends --no-upgrade -o Dpkg::Options::=--force-confnew"

LABEL maintainer="Jordan Daton <jordan@tgrhavoc.co.uk>"
LABEL dradis.version=$DRADIS_VERSION

# Install requirements
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install $APT_ARGS \
		build-essential \
		gcc \
		git \
		libsqlite3-dev \
		make \
		nodejs \
		npm \
		patch \
		zlib1g-dev

#RUN apt-get install $APT_ARGS ssh-client

RUN git clone https://github.com/dradis/dradis-ce.git --branch=$DRADIS_VERSION /dradis

WORKDIR /dradis

# Configure dradis
RUN sed -i "s/ruby '2.4.1'/ruby '\>\= 2.4.1'/" Gemfile && \ 
    sed -i 's@database:\s*db@database: /dbdata@' config/database.yml.template && \
    sed -i 's/config.force_ssl = true/config.force_ssl = false/' config/environments/production.rb && \
    sed -i "s/git@github.com:\(.*\)/https:\/\/github.com\/\1/" Gemfile && \
    sed -i 's/:uglifier/Uglifier.new(harmony: true)/' config/environments/production.rb


RUN gem update --system

# We need to manually setup db so, we need to copy what the setup script does
RUN if [ ! -f "config/database.yml" ]; then cp config/database.yml.template config/database.yml; fi
RUN if [ ! -f config/secrets.yml ]; then cp config/secrets.yml.template config/secrets.yml; fi
RUN if [ ! -f config/smtp.yml ]; then cp config/smtp.yml.template config/smtp.yml; fi

RUN bundle install
RUN rails db:prepare 

# setup should skip what we've already done
RUN ruby bin/setup
RUN cp /dbdata/* /dradis/db/
#RUN ls -la /dradis/db
# Precompile assets
RUN npm install --global yarn && \
	bundle exec rake assets:precompile

# Might as well have all the plugins enabled!
RUN sed -i '/gem/s/^# *//' Gemfile.plugins && \
	bundle install

# Create dradis user:
#RUN groupadd -r dradis && \
#    useradd -r -g dradis -d /dradis dradis && \
#    mkdir -p /dbdata && \
#    chown -R dradis:dradis /dradis/ /dbdata/

# clean image
RUN npm uninstall yarn

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get remove -y --purge \
        build-essential \
        gcc \
        libmariadbd-dev \
        libsqlite3-dev \
        make \
        patch \
        wget \
	npm \
	nodejs \
        zlib1g-dev

RUN DEBIAN_FRONTEND=noninteractive \
    apt install $APT \
        libsqlite3-0 \
        zlib1g

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get autoremove -y

RUN rm -rf /var/cache/apt/archives/* \
        /var/lib/apt/lists/* \
        /dbdata/* \
	/dradis/tmp/*

ADD docker-entrypoint.sh /entrypoint.sh
ADD production.rb /dradis/config/environments/production.rb

RUN mv templates templates_orig 

RUN chmod +x /entrypoint.sh

VOLUME /dradis/templates
VOLUME /dradis/attachments
VOLUME /dbdata

EXPOSE 3000

ENTRYPOINT ["/entrypoint.sh"]
