FROM ros:jazzy-ros-core

RUN apt-get update && apt-get install -y --no-install-recommends \
        alsa-utils python3-numpy python3-rclpy ros-jazzy-std-msgs \
    && rm -rf /var/lib/apt/lists/*

COPY audio_monitor.py /audio_monitor.py

CMD ["/bin/bash", "-c", "source /opt/ros/jazzy/setup.bash && exec python3 /audio_monitor.py"]
