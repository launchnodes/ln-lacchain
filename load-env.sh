#!/bin/bash

# Read the .env file line by line
while IFS= read -r line; do
  # Skip empty lines and comments
  [[ $line =~ ^[[:space:]]*#.*$ || $line =~ ^[[:space:]]*$ ]] && continue

  # Remove leading spaces and set the environment variable
  line=$(echo "$line" | sed -e 's/^[[:space:]]*//')
  export "$line"
done < .env

# Test by printing the environment variables
echo "$CLUSTER_NAME"
echo "$REGION"
