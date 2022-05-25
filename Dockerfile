FROM ubuntu:20.04

# Expose volumes for nginx
VOLUME [ "/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html" ]

# Install required packages for building nginx
RUN apt-get update
RUN ln -snf /usr/share/zoneinfo/$CONTAINER_TIMEZONE /etc/localtime && echo $CONTAINER_TIMEZONE > /etc/timezone
RUN apt-get install -y build-essential zip checkinstall && \
	apt-get install -y perl libperl-dev libgd3 libgd-dev libgeoip1 libgeoip-dev geoip-bin libxml2 libxml2-dev libxslt1.1 libxslt1-dev libgoogle-perftools-dev wget && \
    rm -rf /var/lib/apt/lists/*

# Get all necessary resources
WORKDIR /nginx-src
RUN wget http://nginx.org/download/nginx-1.19.5.tar.gz && tar xzf nginx-1.19.5.tar.gz && rm -f nginx-1.19.5.tar.gz
RUN wget http://zlib.net/fossils/zlib-1.2.11.tar.gz && tar xzf zlib-1.2.11.tar.gz && rm -f zlib-1.2.11.tar.gz
RUN wget http://ftp.exim.org/pub/pcre/pcre-8.44.tar.gz && tar xzf pcre-8.44.tar.gz && rm -f pcre-8.44.tar.gz
RUN wget --no-check-certificate https://www.openssl.org/source/openssl-1.1.1g.tar.gz && tar xzvf openssl-1.1.1g.tar.gz && rm -f openssl-1.1.1g.tar.gz
RUN wget https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/08a395c66e42.zip && unzip 08a395c66e42.zip && rm -f 08a395c66e42.zip

# Build nginx
WORKDIR /nginx-src/nginx-1.19.5/
RUN ./configure --with-cc-opt='-g -O2 -fPIE -fstack-protector-strong -Wformat -Werror=format-security -fPIC -Wdate-time -D_FORTIFY_SOURCE=2' \
--with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro' \
--prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf \
--http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log \
--lock-path=/var/lock/nginx.lock \
--pid-path=/run/nginx.pid \
--modules-path=/usr/lib/nginx/modules \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--with-compat \
--with-debug \
--with-pcre=../pcre-8.44 \
--with-pcre-opt='-g -Ofast -fPIC -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2' \
--with-pcre-jit \
--with-zlib=../zlib-1.2.11 \
--with-zlib-opt='-g -Ofast -fPIC -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2' \
--with-openssl=../openssl-1.1.1g \
--with-openssl-opt=no-nextprotoneg \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_auth_request_module \
--with-http_v2_module \
--with-http_dav_module \
--with-http_slice_module \
--with-threads \
--with-http_addition_module \
--with-http_geoip_module=dynamic \
--with-http_perl_module=dynamic \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_image_filter_module=dynamic \
--with-http_sub_module \
--with-http_xslt_module=dynamic \
--with-stream=dynamic \
--with-stream_geoip_module=dynamic \
--with-stream_ssl_module \
--with-stream_ssl_preread_module \
--with-mail=dynamic \
--with-mail_ssl_module \
--add-module=../nginx-goodies-nginx-sticky-module-ng-08a395c66e42

RUN make

RUN make install

# Extra settings to make nginx happier to work with
WORKDIR /etc/nginx
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf
RUN mkdir -p /var/lib/nginx/body
ENV PATH=/usr/share/nginx/sbin:$PATH
CMD [ "nginx" ]
EXPOSE 80
EXPOSE 443
