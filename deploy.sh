#!/bin/bash

set -e

# Optional debug
echo "Starting Ansible deployment..."

# Run the playbook using the Ansible inventory file
ansible-playbook -i ansible/inventory.ini ansible/install_openemr.yml
