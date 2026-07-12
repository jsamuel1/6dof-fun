# foxglove_bridge for ROS2 Jazzy.
#
# There is no official Foxglove-published Docker image for the ROS2 bridge
# (the ros-foxglove-bridge repo is ROS1-only; ROS2 ships as the apt package
# ros-jazzy-foxglove-bridge), so we build a minimal one.
#
# ros:jazzy-ros-base is a multi-arch OSRF image (linux/amd64 + linux/arm64),
# so this builds natively on both Docker Desktop for macOS (Apple Silicon)
# and a 64-bit Raspberry Pi.
#
# Built automatically by `docker compose up` from host/docker-compose.yml.

FROM ros:jazzy-ros-base

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ros-jazzy-foxglove-bridge \
    && rm -rf /var/lib/apt/lists/*

# The base image's /ros_entrypoint.sh sources /opt/ros/jazzy/setup.bash,
# so plain `ros2 ...` commands work as CMD/command.
CMD ["ros2", "launch", "foxglove_bridge", "foxglove_bridge_launch.xml", "port:=8765", "address:=0.0.0.0"]
