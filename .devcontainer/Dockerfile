FROM --platform=amd64 mcr.microsoft.com/devcontainers/ruby:1-3.3-bookworm

# Install Rails
RUN su vscode -c "gem install rails webdrivers"
RUN su vscode -c "/usr/local/rvm/bin/rvm fix-permissions"

# Default value to allow debug server to serve content over GitHub Codespace's port forwarding service
# The value is a comma-separated list of allowed domains 
ENV RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev,.preview.app.github.dev,.app.github.dev"

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get -yq dist-upgrade && \
    apt-get install -y --no-install-recommends build-essential \
        git \
        libicu-dev \
        libidn11-dev \
        libpq-dev \
        libjemalloc-dev \
        zlib1g-dev \
        libgdbm-dev \
        libgmp-dev \
        libssl-dev \
        libyaml-0-2 \
        ca-certificates \
        libreadline8 \
        python3 \
        shared-mime-info
    # bundle config set --local deployment 'true' && \
    # bundle config set --local without 'development test' && \
    # bundle config set silence_root_warning true && \
    # bundle install -j"$(nproc)" && \
    # yarn install --pure-lockfile --production --network-timeout 600000 && \
    # yarn cache clean

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment this line to install additional gems.
# RUN su vscode -c "gem install <your-gem-names-here>"

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1
