# Camera publisher for the Pi host stack.
#
# Default: usb_cam (any UVC USB webcam on /dev/video0).
#
# Pi Camera Module (ribbon cable) instead? usb_cam cannot drive it — it
# needs libcamera. Swap the apt package below for ros-jazzy-camera-ros,
# change the compose command to `ros2 run camera_ros camera_node`, and add
# these to the camera service in docker-compose.yml:
#     devices: [/dev/dma_heap, /dev/vchiq, /dev/video0]
#     volumes: [/run/udev:/run/udev:ro]

FROM ros:jazzy-ros-base

RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-jazzy-usb-cam \
        ros-jazzy-image-transport-plugins \
    && rm -rf /var/lib/apt/lists/*

# image-transport-plugins provides /image_raw/compressed (JPEG) — use that
# topic in Foxglove over WiFi; raw is ~26 MB/s at 640x480x15.
