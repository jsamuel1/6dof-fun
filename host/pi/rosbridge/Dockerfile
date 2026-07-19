# Shared image for the web UI's two ROS-side services:
#   arm-rosbridge  — rosbridge_server websocket (JSON <-> DDS) on :9090
#   arm-web-video  — web_video_server MJPEG streamer on :8080
FROM ros:jazzy-ros-core

RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-jazzy-rosbridge-server \
        ros-jazzy-web-video-server \
    && rm -rf /var/lib/apt/lists/*
