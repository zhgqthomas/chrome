FROM ubuntu:18.04

# Build Args
ARG USE_CHROME_STABLE

# Application parameters and variables
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3000 \
    application_directory=/usr/src/app \
    ENABLE_XVBF=true \
    # Configuration for Chrome
    CONNECTION_TIMEOUT=60000 \
    CHROME_PATH=/usr/bin/google-chrome \
    USE_CHROME_STABLE=${USE_CHROME_STABLE}

WORKDIR $application_directory

# Bundle app source
COPY . .

# It's a good idea to use dumb-init to help prevent zombie chrome processes.
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/local/bin/dumb-init

# Dependencies + NodeJS
RUN apt-get -qq update && \
  echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
  apt-get -y -qq install software-properties-common &&\
  apt-add-repository "deb http://archive.canonical.com/ubuntu $(lsb_release -sc) partner" && \
  apt-add-repository ppa:malteworld/ppa && apt-get -qq update && apt-get -y -qq install \
  adobe-flashplugin \
  msttcorefonts \
  fonts-noto-color-emoji \
  fonts-noto-cjk \
  fonts-liberation \
  fonts-thai-tlwg \
  fonts-indic \
  fontconfig \
  libappindicator3-1 \
  pdftk \
  unzip \
  locales \
  gconf-service \
  libasound2 \
  libatk1.0-0 \
  libc6 \
  libcairo2 \
  libcups2 \
  libdbus-1-3 \
  libexpat1 \
  libfontconfig1 \
  libgcc1 \
  libgconf-2-4 \
  libgdk-pixbuf2.0-0 \
  libglib2.0-0 \
  libgtk-3-0 \
  libnspr4 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libstdc++6 \
  libx11-6 \
  libx11-xcb1 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxrender1 \
  libxss1 \
  libxtst6 \
  ca-certificates \
  libappindicator1 \
  libnss3 \
  lsb-release \
  xdg-utils \
  wget \
  xvfb \
  curl &&\
  # Install Node
  curl --silent --location https://deb.nodesource.com/setup_10.x | bash - &&\
  apt-get -y -qq install nodejs &&\
  apt-get -y -qq install build-essential &&\
  # Fonts
  fc-cache -f -v &&\
  # use dumb-init
  chmod +x /usr/local/bin/dumb-init &&\
  # Install Chrome Stable when specified
  if [ "$USE_CHROME_STABLE" = "true" ]; then \
    cd /tmp &&\
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &&\
    dpkg -i google-chrome-stable_current_amd64.deb;\
  fi &&\
  # Build
  if [ "$USE_CHROME_STABLE" = "true" ]; then \
    export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true;\
  fi &&\
  npm install -g typescript @types/node &&\
  npm install &&\
  npm run post-install &&\
  npm run build && \
  # Cleanup
  apt-get -qq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\
  # Add user
  groupadd -r blessuser && useradd -r -g blessuser -G audio,video blessuser \
  && mkdir -p /home/blessuser/Downloads \
  && chown -R blessuser:blessuser /home/blessuser \
  && chown -R blessuser:blessuser $application_directory

# Run everything after as non-privileged user.
USER blessuser

# Expose the web-socket and HTTP ports
EXPOSE 3000
ENTRYPOINT ["dumb-init", "--"]
CMD [ "node", "./build/index.js" ]
