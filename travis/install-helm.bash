#!/bin/bash

# Install helm.

set -xeuo pipefail

URL="https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get"

curl ${URL} | sudo bash
