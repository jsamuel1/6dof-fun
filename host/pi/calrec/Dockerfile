FROM ros:jazzy-ros-core

RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-jazzy-rclpy ros-jazzy-std-msgs ros-jazzy-sensor-msgs \
    && rm -rf /var/lib/apt/lists/*

COPY calrec.py /calrec.py

CMD ["/bin/bash", "-c", "source /opt/ros/jazzy/setup.bash && exec python3 /calrec.py"]
