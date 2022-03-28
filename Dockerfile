FROM centos:7.9.2009

ARG nginx=nginx-1.16.1-1.el7.ngx.x86_64.rpm

RUN true \
  && yum -y upgrade \
  && yum install -y \
    openssl \
    gettext

RUN true \
  && curl -O https://nginx.org/packages/centos/7/x86_64/RPMS/${nginx} \
  && rpm -i ${nginx} \
  && rm ${nginx}

EXPOSE 443

COPY docker-entrypoint.sh /
COPY docker-entrypoint.d /docker-entrypoint.d

COPY templates /etc/nginx/templates/

COPY www /www

CMD ["nginx", "-g", "daemon off;"]

ENTRYPOINT ["/docker-entrypoint.sh"]
