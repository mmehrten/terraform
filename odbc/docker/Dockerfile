FROM public.ecr.aws/ubuntu/ubuntu:latest 

RUN mkdir /odbc
WORKDIR /odbc

# Set up apt
RUN apt-get update
RUN apt install -y curl lsb-release wget gpg less jq openjdk-17-jdk git vim dnsutils 

# MSSQL
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg \
    &&  curl https://packages.microsoft.com/config/debian/12/prod.list | tee /etc/apt/sources.list.d/mssql-release.list \
    &&  apt-get update

RUN ACCEPT_EULA=Y apt install -y msodbcsql18 \
    && ACCEPT_EULA=Y apt install -y mssql-tools18 

RUN apt install -y unixodbc-dev

# PostgreSQL
RUN apt install -y odbc-postgresql

# Python
RUN apt install -y python3.12 python3-pip python3.12-venv \
    && python3.12 -m venv default 

COPY requirements.txt .
RUN default/bin/pip install -r requirements.txt

RUN echo "source $(pwd)/default/bin/activate" >> ~/.profile
ENTRYPOINT [ "sleep", "infinity" ]