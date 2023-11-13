#   Copyright IBM Corporation 2021
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

FROM registry.access.redhat.com/ubi8/ubi:latest AS builder
RUN yum install -y java-17-openjdk-devel
RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz https://archive.apache.org/dist/maven/maven-3/3.8.4/binaries/apache-maven-3.8.4-bin.tar.gz \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn
COPY . /app
WORKDIR /app
RUN mvn package -Dmaven.test.skip

FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
RUN microdnf update && microdnf install -y java-17-openjdk-devel wget tar gzip shadow-utils && microdnf clean all
WORKDIR /usr/local
ENV CATALINA_PID='/usr/local/tomcat10/temp/tomcat.pid' CATALINA_HOME='/usr/local/tomcat10' CATALINA_BASE='/usr/local/tomcat10'
RUN wget https://downloads.apache.org/tomcat/tomcat-10/v10.0.14/bin/apache-tomcat-10.0.14.tar.gz && tar -zxf apache-tomcat-10.0.14.tar.gz && rm -f apache-tomcat-10.0.14.tar.gz && mv apache-tomcat-10.0.14 tomcat10 && rm -r "$CATALINA_BASE"/webapps/ROOT
RUN adduser -r tomcat && chown -R tomcat:tomcat tomcat10
COPY --chown=tomcat:tomcat --from=builder /app/target/hello-world.war "$CATALINA_BASE"/webapps-javaee/
USER tomcat:tomcat
EXPOSE 8080
CMD [ "/usr/local/tomcat10/bin/catalina.sh", "run" ]
