#!/usr/bin/env bash

# This script template is expected to be populated during the setup of a
# Heracles nginx. It runs on host startup.

# Log everything we do.
set -x
exec > /var/log/user-data.log 2>&1

# Allow the ec2-user to sudo without a tty, which is required when we run post
# install scripts on the server.
echo Defaults:ec2-user \!requiretty >> /etc/sudoers

# Setup AZ
mkdir -p /etc/aws/
cat > /etc/aws/aws.conf <<- EOF
[Global]
Zone = ${availability_zone}
EOF

# Update Repos
yum update -y

# Install Cloudwatch
yum install -y awslogs

# Configure Cloudwatch
cat > /etc/awslogs/awslogs.conf <<- EOF
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/messages]
log_stream_name = ${log_stream_name}
log_group_name = /var/log/messages
file = /var/log/messages
datetime_format = %b %d %H:%M:%S
buffer_duration = 5000
initial_position = start_of_file

[/var/log/user-data.log]
log_stream_name = ${log_stream_name}
log_group_name = /var/log/user-data.log
file = /var/log/user-data.log
EOF

# Start the awslogs service, also start on reboot.
# Note: Errors go to /var/log/awslogs.log
systemctl enable awslogsd.service
systemctl start awslogsd

# Update Packages
yum-config-manager --enable epel

# Install Ansible
yum -y install ansible