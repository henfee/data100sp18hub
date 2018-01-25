#!/bin/bash

# Install helm.

set -euo pipefail

URL="https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get"

curl -o /tmp/helm.bash ${URL}
sudo bash /tmp/helm.bash --version v2.7.2
