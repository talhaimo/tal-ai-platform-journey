#!/bin/bash

set -e

# Detect the actual logged-in user even if run via sudo
USER_NAME="$(logname)"
HOME_DIR="/home/$USER_NAME"
ANACONDA_INSTALLER="Anaconda3-2024.10-1-Linux-x86_64.sh"
ANACONDA_URL="https://repo.anaconda.com/archive/$ANACONDA_INSTALLER"
TMP_PATH="/tmp/$ANACONDA_INSTALLER"
CONDA_DIR="$HOME_DIR/anaconda3"
JUPYTER_BIN="$CONDA_DIR/bin/jupyter"
SYSTEMD_SERVICE="/etc/systemd/system/jupyter.service"

echo "=== [1/7] Downloading Anaconda installer to /tmp ==="
wget -q --show-progress -O "$TMP_PATH" "$ANACONDA_URL"

echo "=== [2/7] Installing Anaconda silently from /tmp ==="
bash "$TMP_PATH" -b -p "$CONDA_DIR"

echo "=== Cleaning up installer ==="
rm -f "$TMP_PATH"

echo "=== [3/7] Generating Jupyter config ==="
sudo -u "$USER_NAME" "$JUPYTER_BIN" lab --generate-config

echo "=== [4/7] Setting Jupyter password (prompting) ==="
sudo -u "$USER_NAME" "$JUPYTER_BIN" notebook password

echo "=== [5/7] Updating JupyterLab via conda-forge ==="
sudo -u "$USER_NAME" "$CONDA_DIR/bin/conda" update -y -c conda-forge jupyterlab

echo "=== [6/7] Creating systemd service ==="
sudo tee "$SYSTEMD_SERVICE" > /dev/null <<EOF
[Unit]
Description=Jupyter Lab
After=network.target

[Service]
Type=simple
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$HOME_DIR
ExecStart=$JUPYTER_BIN-lab --no-browser --ip=0.0.0.0 --port=8888
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "=== [7/7] Enabling and starting the Jupyter service ==="
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable jupyter
sudo systemctl start jupyter

echo "✅ JupyterLab installed and running as a systemd service."
echo "➡️ Visit: http://<your-ip>:8888"