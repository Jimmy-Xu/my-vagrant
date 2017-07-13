FROM ceph/demo:tag-build-master-jewel-ubuntu-16.04
MAINTAINER xjimmyshcn@gmail.com

#xmllint process xml(libxml2-utils include xmllint)
#jq process json
RUN env; apt-get update && apt-get install -y python-pip curl libxml2-utils jq vim \
    && apt-get clean && rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pip install --upgrade pip
RUN pip install s3cmd
RUN pip install python-swiftclient
RUN echo "export TERM=vt100" >> /root/.bashrc

##################################################
# Add bootstrap script
ADD entrypoint.sh /entrypoint.sh

# Add volumes for Ceph config and data
VOLUME ["/etc/ceph","/var/lib/ceph","/var/log/ceph"]

# Expose the Ceph ports
# (change 80 to 8800, avoid conflict with other web server
# change 5000 to 5500, avoid conflict with docker register)
EXPOSE 6789 6800 6801 6802 6803 6804 6805 8800 5500

# Execute the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
