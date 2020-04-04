FROM openjdk:8-alpine

LABEL maintainer="Alex Shamuel<theshamuel@gmail.com>"

ENV \
    MAVEN_VERSION=3.6.3 \
    MVN_HOME=/srv/maven \
    TZ=UTC

RUN \
    apk add --no-cache --update tzdata git bash curl && \
    rm -rf /var/cache/apk/*

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
        echo "export PATH=$PATH:$MVN_HOME:$MVN_HOME/bin;" >> /etc/profile; \
        tar -C /srv/maven -zxf /srv/maven/maven.tar.gz; \
        find /srv/maven -type f -name '*tar.gz*' -delete; \
        maven_folder=/srv/maven/$(ls); \
        mv -f $maven_folder/* /srv/maven/; \
        rm -rf $maven_folder; \
        /srv/maven/bin/mvn --version; \
    else echo "[ERROR] Checksum does not match"; fi
