#!/bin/bash

# Log file
LOG_FILE="outputbinfile.log"

# Function to log system resource usage
log_usage() {
    TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

    # CPU usage (1-minute average)
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

    # Log CPU usage
    echo "$TIMESTAMP | CPU Usage: $CPU_USAGE%" >> "$LOG_FILE"

    # If CPU > 75%, create a GCP VM
    if (( $(echo "$CPU_USAGE > 75" | bc -l) )); then
        echo "$TIMESTAMP | ALERT: CPU exceeded 75%, launching GCP VM!" >> "$LOG_FILE"

        # Create GCP VM
        gcloud compute instances create flask-instance \
            --machine-type=e2-micro \
            --image-family=debian-11 \
            --image-project=debian-cloud \
            --tags=http-server \
            --metadata=startup-script='#!/bin/bash
            apt update && apt install -y python3 python3-pip
            pip3 install flask
            echo "from flask import Flask
            app = Flask(__name__)
            @app.route('/')
            def home():
                return \"Hello from GCP VM!\"
            if __name__ == \"__main__\":
                app.run(host=\"0.0.0.0\", port=5000)" > /home/flask_app.py
            python3 /home/flask_app.py &'

        echo "$TIMESTAMP | GCP VM Launched!" >> "$LOG_FILE"
    fi
}

# Run every 10 seconds
while true; do
    log_usage
    sleep 3
done