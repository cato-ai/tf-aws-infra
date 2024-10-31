    #!/bin/bash
    touch /opt/webapp/.env
    DB_NAME="${db_name}"
    DB_USER="${db_user}"
    DB_PASSWORD="${db_password}"
    S3_NAME="${s3_name}"
    echo DB_CONNECTION_URL="postgres://${db_user}:${db_password}@${db_endpoint}/$DB_NAME" >> /opt/webapp/.env
    echo SERVER_HOSTNAME="${server_hostname}" >> /opt/webapp/.env
    echo SERVER_PORT_NUMBER="${server_port_number}" >> /opt/webapp/.env
    echo S3_NAME=$S3_NAME >> /opt/webapp/.env

    # Set permissions for the .env file
    sudo chmod 600 /opt/webapp/.env
    sudo chown -R csye6225:csye6225 /opt/webapp/.env
    sudo rm -rf /opt/webapp/build 
    cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
    "metrics": {
        "namespace": "webapp_dev",
        "metrics_collected": {
        "statsd": 
            {
                "service_address": ":8125",
                "metrics_collection_interval": 1,
                "metrics_aggregation_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
        "files": 
            {
                "collect_list": [
                    {
                        "file_path": "/var/log/syslog",
                        "log_group_name": "/aws/ec2/webapp_csye6225",
                        "log_stream_name": "webapp/syslog",
                        "retention_in_days": 1
                    }
                ]
            }
        }
    }
    }
    EOF

    sudo chown cwagent:cwagent /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    sudo chmod 644 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    sudo chmod 644 /var/log/syslog
    sudo systemctl daemon-reload
    sudo systemctl restart amazon-cloudwatch-agent

    systemctl restart csye6225.service
