FROM ruby:3.2.3

WORKDIR /app

RUN apt-get update -qq && apt-get install -y \
    build-essential \
    git \
    libmariadb-dev \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    nodejs \
    yarn \
    libvips \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy gem configs
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the app
COPY . /app

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
