FROM openjdk:8-alpine

LABEL maintainer="Alex Shamuel<theshamuel@gmail.com>"

ENV \
    MAVEN_VERSION=3.6.3 \
    GLIBC_VERISON=2.31-r0 \
    MVN_HOME=/srv/maven \
    TZ=UTC \
    LC_ALL=C

RUN \
    apk add --no-cache --update tzdata git bash curl && \
    rm -rf /var/cache/apk/*

#Install glibc for working with embeded mondgo test lib flapdoodle
RUN \
    cd /tmp && \
    curl -Lko /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    curl -Lko glibc-${GLIBC_VERISON}.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERISON}/glibc-${GLIBC_VERISON}.apk && \
    apk add glibc-${GLIBC_VERISON}.apk && \
    curl -Lko glibc-bin-${GLIBC_VERISON}.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERISON}/glibc-bin-${GLIBC_VERISON}.apk && \
    curl -Lko glibc-i18n-${GLIBC_VERISON}.apk https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERISON}/glibc-i18n-${GLIBC_VERISON}.apk && \
    apk add glibc-bin-${GLIBC_VERISON}.apk glibc-i18n-${GLIBC_VERISON}.apk && \
    /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    rm -f /tmp/*.apk

#Download Maven
RUN \
    mkdir -p /srv/maven && \
    cd /srv/maven && \
    curl -Lko maven.tar.gz https://ftp.heanet.ie/mirrors/www.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    curl -Lko maven.tar.gz.sha512.original https://downloads.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz.sha512

WORKDIR /srv/maven

#Check sha512 of tarball and install Maven
RUN \
    sha512sum maven.tar.gz | awk '{printf "%s", $1}' > maven.tar.gz.sha512 && \
    diff_checksum=$(diff /srv/maven/maven.tar.gz.sha512 /srv/maven/maven.tar.gz.sha512.original) && \
    echo "[INFO] Original sha512  =$(cat /srv/maven/maven.tar.gz.sha512.original)" && \
    echo "[INFO] Calculated sha512=$(cat /srv/maven/maven.tar.gz.sha512.original)" && \
    echo "[INFO] diff_checksum=$diff_checksum" && \
    if [ -z "$diff_checksum" ]; then \
        echo "PATH=$PATH:$MVN_HOME:$MVN_HOME/bin" >> /etc/profile; \
        tar -C /srv/maven -zxf /srv/maven/maven.tar.gz; \
        find /srv/maven -type f -name '*tar.gz*' -delete; \
        maven_folder=/srv/maven/$(ls); \
        mv -f $maven_folder/* /srv/maven/; \
        rm -rf $maven_folder; \
        /srv/maven/bin/mvn --version; \
    else echo "[ERROR] Checksum does not match"; fi
