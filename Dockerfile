FROM ubuntu:22.04
MAINTAINER = silencej <owen263@gmail.com>
ENV TRAC_ADMIN_NAME trac_admin
ENV TRAC_ADMIN_PASSWD passw0rd
ENV TRAC_PROJECT_NAME trac_project
ENV TRAC_DIR /var/local/trac
ENV TRAC_INI $TRAC_DIR/conf/trac.ini
ENV DB_LINK sqlite:db/trac.db
EXPOSE 8123

# Run this in China
RUN sed -i 's/archive/cn.archive/g' /etc/apt/sources.list

# Install apache2-utils for `htdigest`
RUN apt-get update && apt-get install -y python2 python-pip apache2-utils

# Run this in China
RUN pip2 config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

RUN pip2 install --upgrade babel docutils pygments textile trac pytz TracAccountManager
COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh
ENTRYPOINT /docker-entrypoint.sh
