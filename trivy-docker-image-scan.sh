#!/bin/sh

dockerImageName=$(awk 'NR==1 {print $2}' Dockerfile)
echo $dockerImageName

/usr/local/bin/trivy -q image --exit-code 1 --severity HIGH,CRITICAL $dockerImageName

    # Trivy scan result processing
    exit_code=$?
    echo "Exit Code : $exit_code"

    # Check scan results
    if [[ "${exit_code}" == 1 ]]; then
        echo "Image scanning failed. Vulnerabilities found"
        exit 1;
    else
        echo "Image scanning passed. No CRITICAL vulnerabilities found"
    fi;
