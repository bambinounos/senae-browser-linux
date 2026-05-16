FROM ubuntu:24.04

LABEL maintainer="SENAE Browser Container"
LABEL description="Firefox 41 + Java 7 + Flash 25 para Ecuapass"

ENV DEBIAN_FRONTEND=noninteractive

# Dependencias del sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgtk2.0-0t64 \
    libxt6t64 \
    libdbus-glib-1-2 \
    libasound2t64 \
    libxtst6 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxcursor1 \
    libxi6 \
    libcanberra-gtk-module \
    libgl1 \
    libnss3 \
    libnspr4 \
    desktop-file-utils \
    xdg-utils \
    ca-certificates \
    curl \
    wget \
    bzip2 \
    unzip \
    locales \
    && rm -rf /var/lib/apt/lists/*

# Locale español
RUN locale-gen es_EC.UTF-8
ENV LANG=es_EC.UTF-8
ENV LC_ALL=es_EC.UTF-8

# Firefox 41.0.2
RUN wget -q "https://ftp.mozilla.org/pub/firefox/releases/41.0.2/linux-x86_64/es-ES/firefox-41.0.2.tar.bz2" \
    -O /tmp/firefox.tar.bz2 && \
    tar xjf /tmp/firefox.tar.bz2 -C /opt/ && \
    mv /opt/firefox /opt/senae-browser && \
    rm /tmp/firefox.tar.bz2

# Java 7: acepta JRE (jre-7u80-...) o JDK (jdk-7u80-...) -- el JDK contiene el JRE
COPY j*-7u80-linux-x64.tar.gz /tmp/java7.tar.gz
RUN tar xzf /tmp/java7.tar.gz -C /opt/ && rm /tmp/java7.tar.gz && \
    if [ -d /opt/jdk1.7.0_80 ] && [ ! -d /opt/jre1.7.0_80 ]; then \
        ln -s /opt/jdk1.7.0_80/jre /opt/jre1.7.0_80; \
    fi
ENV JAVA_HOME=/opt/jre1.7.0_80
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Flash Player 25 NPAPI (copiar desde build context)
COPY libflashplayer.so /opt/flash/
RUN mkdir -p /usr/lib/mozilla/plugins && \
    ln -s /opt/flash/libflashplayer.so /usr/lib/mozilla/plugins/libflashplayer.so

# Plugin Java NPAPI
RUN ln -s /opt/jre1.7.0_80/lib/amd64/libnpjp2.so /usr/lib/mozilla/plugins/libnpjp2.so

# Configuración Flash - mms.cfg
RUN mkdir -p /etc/adobe && \
    echo "RSLVerifyDigitalSignatures=0" > /etc/adobe/mms.cfg && \
    echo "SilentAutoUpdateEnable=0" >> /etc/adobe/mms.cfg && \
    echo "AutoUpdateDisable=1" >> /etc/adobe/mms.cfg && \
    echo "EOLUninstallDisable=1" >> /etc/adobe/mms.cfg && \
    echo "EnableAllowList=0" >> /etc/adobe/mms.cfg

# Crear usuario no-root
RUN useradd -m -s /bin/bash senae
USER senae
WORKDIR /home/senae

# Configuración Java
RUN mkdir -p /home/senae/.java/deployment/security && \
    echo "https://ecuapass.aduana.gob.ec" > /home/senae/.java/deployment/security/exception.sites && \
    echo "http://ecuapass.aduana.gob.ec" >> /home/senae/.java/deployment/security/exception.sites && \
    echo "https://portal.aduana.gob.ec" >> /home/senae/.java/deployment/security/exception.sites

RUN echo "deployment.security.level=MEDIUM" > /home/senae/.java/deployment/deployment.properties && \
    echo "deployment.expiration.check.enabled=false" >> /home/senae/.java/deployment/deployment.properties && \
    echo "deployment.security.validation.ocsp=false" >> /home/senae/.java/deployment/deployment.properties && \
    echo "deployment.security.validation.crl=false" >> /home/senae/.java/deployment/deployment.properties && \
    echo "deployment.insecure.jres=ALWAYS" >> /home/senae/.java/deployment/deployment.properties && \
    echo "deployment.security.expired.certificate=true" >> /home/senae/.java/deployment/deployment.properties

# Perfil Firefox con preferencias
RUN mkdir -p /home/senae/.senae-profile && \
    echo 'user_pref("plugin.state.java", 2);' > /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("plugin.state.npjp2", 2);' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("plugin.state.npdeployjava1", 2);' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("plugin.state.flash", 2);' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("plugin.state.libflashplayer", 2);' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("plugin.scan.plid.all", true);' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("security.mixed_content.block_active_content", false);' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("browser.startup.homepage", "https://ecuapass.aduana.gob.ec");' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("browser.download.folderList", 2);' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("browser.download.dir", "/home/senae/Descargas");' >> /home/senae/.senae-profile/prefs.js && \
    echo 'user_pref("browser.download.useDownloadDir", true);' >> /home/senae/.senae-profile/prefs.js && \
    mkdir -p /home/senae/Descargas

# Plugins accesibles para el perfil
RUN mkdir -p /home/senae/.mozilla/plugins && \
    ln -s /opt/flash/libflashplayer.so /home/senae/.mozilla/plugins/libflashplayer.so && \
    ln -s /opt/jre1.7.0_80/lib/amd64/libnpjp2.so /home/senae/.mozilla/plugins/libnpjp2.so

ENV MOZ_PLUGIN_PATH=/home/senae/.mozilla/plugins

ENTRYPOINT ["/opt/senae-browser/firefox", "-no-remote", "-profile", "/home/senae/.senae-profile"]
CMD ["https://ecuapass.aduana.gob.ec"]
