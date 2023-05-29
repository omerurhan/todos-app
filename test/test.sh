#!/bin/sh

echodsd
if [[ ${exit_code} -ne 0 ]];
  then
    echo "OWASP ZAP Report has either Low/Medium/High Risk. Please check the HTML Report"
    exit 1;
  else
    echo "OWASP ZAP did not report any Risk"
fi
