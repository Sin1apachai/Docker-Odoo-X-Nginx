FROM ubuntu:22.04

SHELL ["/bin/bash", "-xo", "pipefail", "-c"]

USER root

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get upgrade -y

ENV TZ=Asia/Bangkok

RUN adduser -system -home=/opt/odoo -group odoo
RUN usermod -aG root odoo 

RUN apt update -y
RUN apt -y install python3-pip wget python3-dev python3-venv python3-wheel \
                   libxml2-dev libpq-dev libjpeg8-dev liblcms2-dev libxslt1-dev \ 
                   zlib1g-dev libsasl2-dev libldap2-dev build-essential git \ 
                   libssl-dev libffi-dev libmysqlclient-dev libjpeg-dev libblas-dev \
                   libatlas-base-dev xfonts-75dpi xfonts-base fontconfig \
                   nodejs node-less npm

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
RUN dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
RUN rm -rf libssl1.1_1.1.0g-2ubuntu4_amd64.deb
RUN wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.focal_amd64.deb
RUN chmod +x wkhtmltox_0.12.6-1.focal_amd64.deb
RUN apt install ./wkhtmltox_0.12.6-1.focal_amd64.deb
RUN rm -rf ./wkhtmltox_0.12.6-1.focal_amd64.deb
RUN ln -s /usr/local/bin/wkhtmltopdf /usr/bin/wkhtmltopdf

RUN npm install -g rtlcss less less-plugin-clean-css
RUN apt -y install xfonts-75dpi xfonts-base fontconfig
RUN git clone {odoo} /opt/odoo/odoo-server

COPY ./requirements.txt /opt/odoo/odoo-server/requirements.txt
RUN chown -R odoo:root /opt/odoo/odoo-server/*
RUN pip3 install -r /opt/odoo/odoo-server/requirements.txt

RUN apt install lsb-core -y
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN apt update -y
RUN apt install postgresql-15 postgresql-contrib-15 -y

COPY ./config/odoo.conf /etc/odoo.conf
RUN chown odoo:root /etc/odoo.conf

RUN ln -s /opt/odoo/odoo-server/odoo-bin /usr/local/bin/odoo

RUN apt-get install fonts-thai-tlwg -y

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY wait-for-psql.py /usr/local/bin/wait-for-psql.py

RUN chmod +x /usr/local/bin/wait-for-psql.py
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/odoo

RUN mkdir /var/lib/odoo
RUN mkdir /var/log/odoo

RUN apt -y install nginx
COPY ./nginx/odoo.conf /etc/nginx/sites-available/odoo.conf
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/key.key /etc/ssl/nginx/key.key
COPY ./nginx/chain.pem /etc/ssl/nginx/chain.pem
COPY ./nginx/certificate.pem /etc/ssl/nginx/certificate.pem
RUN rm /etc/nginx/sites-enabled/default
RUN rm /etc/nginx/sites-available/default
RUN ln -s /etc/nginx/sites-available/odoo.conf /etc/nginx/sites-enabled/odoo.conf

RUN chown -R odoo:root /etc/nginx
RUN chown -R odoo:root /etc/ssl

WORKDIR /var/lib/
RUN chown -R odoo:root odoo
RUN chown -R odoo:root nginx

WORKDIR /var/log/
RUN chown -R odoo:root odoo
RUN chown -R odoo:root nginx

USER odoo

WORKDIR /opt/odoo/odoo-server

ENV OPTIONS ""
ENV ODOO_RC /etc/odoo.conf

EXPOSE 8069 8071 8072

ENTRYPOINT ["entrypoint.sh"]

CMD ["odoo"]
     
