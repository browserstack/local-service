FROM 737963123736.dkr.ecr.us-east-1.amazonaws.com/browserstack/base-buildpack-deps:v-2023-04-01
ARG ssh_prv_key

RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN  ln -s /bin/mkdir /usr/bin/mkdir \
&& curl -sSL https://get.rvm.io | bash -s stable --ruby \
&& echo 'source /usr/local/rvm/scripts/rvm' >> ~/.bashrc

RUN . ~/.bashrc \
    && rvm install 3.2.3 \
    && rvm use 3.2.3 --default \
    && gem install bundler -v 2.3.7


RUN apt-get update -qq && apt-get install -y \
  build-essential=12.9 --no-install-recommends \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy gem configs
COPY Gemfile Gemfile.lock ./

USER app

RUN bundle install

# Copy the rest of the app
COPY . /app

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
