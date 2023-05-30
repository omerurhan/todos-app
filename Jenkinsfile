pipeline {
  agent any
    environment {
        namespace = "dev"
        appName = "todos"
        commitId = "${sh(script:'git rev-parse --short HEAD', returnStdout: true)}"
        applicationDNS = "todos.demo.io"
    }
    stages {
      stage('Sonarqube SAST') {
      agent {
        kubernetes {
          defaultContainer 'sonarscanner'
          yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: sonarscanner
                image: sonarsource/sonar-scanner-cli
                command:
                - sleep
                args:
                - 99d
            '''
        }
      }
      steps {
        withSonarQubeEnv('sonarqube') {
          sh 'sonar-scanner \
           -Dsonar.projectKey=todos \
           -Dsonar.sources=. \
           -Dsonar.host.url=http://sonarqube.demo.io'
        }
        timeout(time: 3, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: true
        }
      }
    }
    stage('Vulnerability Scan - Docker') {
      parallel {
        stage ("Go dependency Check") {
          agent {
            kubernetes {
              defaultContainer 'golang'
              yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: golang
                    image: golang:1.20
                    command:
                    - sleep
                    args:
                    - 99d
                '''
            }
          }
          steps {
              sh 'go install golang.org/x/vuln/cmd/govulncheck@latest'
              sh 'govulncheck ./...'
          }
        }
        stage ("Trivy Scan") {
          agent {
            kubernetes {
              defaultContainer 'trivy'
              yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: trivy
                    image: aquasec/trivy:0.41.0
                    command:
                    - sleep
                    args:
                    - 99d
                '''
            }
          }
          steps {
            sh 'sh trivy-docker-image-scan.sh'
          }
        }
        stage ("OPA Conftest") {
          agent {
            kubernetes {
              defaultContainer 'conftest'
              yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: conftest
                    image: openpolicyagent/conftest
                    command:
                    - sleep
                    args:
                    - 99d
                '''
            }
          }
          steps {
            sh 'conftest test --policy opa-docker-security.rego Dockerfile'
          }
        }
      }
    }
        stage('Build artifact') {
          agent {
            kubernetes {
              label 'jenkinsrun'
              defaultContainer 'golang'
              yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: golang
                    image: golang:1.20
                    command:
                    - sleep
                    args:
                    - 99d
                '''
              }
          }
          steps {
            sh 'go mod download'
            sh  'CGO_ENABLED=0 GOOS=linux go build -buildvcs=false -o todos'
            stash includes: 'todos', name: 'app'
          }
        }
    stage('Build Docker Container and Push') {
      agent {
        kubernetes {
          defaultContainer 'kaniko'
          yaml '''
            kind: Pod
            spec:
              containers:
              - name: kaniko
                image: gcr.io/kaniko-project/executor:v1.6.0-debug
                imagePullPolicy: Always
                command:
                - sleep
                args:
                - 99d
                volumeMounts:
                  - name: jenkins-docker-cfg
                    mountPath: /kaniko/.docker
              volumes:
              - name: jenkins-docker-cfg
                projected:
                  sources:
                  - secret:
                      name: regcred
                      items:
                        - key: .dockerconfigjson
                          path: config.json
                '''
        }
      }
      steps {
        unstash 'app'
        sh 'printenv'
        sh '/kaniko/executor -f `pwd`/Dockerfile -c `pwd` --force --insecure --skip-tls-verify --cache=true --destination=omerurhan/todos:${commitId}'
      }
    }
    stage ('Vulnerability Scan - Kubernetes') {
      parallel {
        stage ('Opa conftest kubernetes'){
        agent {
        kubernetes {
          defaultContainer 'conftest'
          yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: conftest
                image: openpolicyagent/conftest
                command:
                - sleep
                args:
                - 99d
            '''
        }
      }
      steps {
        sh 'conftest test --policy opa-k8s-security.rego kubernetes/deployment.yaml'
        sh 'conftest test --policy opa-k8s-security.rego kubernetes/service.yaml'
      }
        }
        stage ("Trivy Scan for ready container") {
          agent {
            kubernetes {
              defaultContainer 'trivy'
              yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: trivy
                    image: aquasec/trivy:0.41.0
                    command:
                    - sleep
                    args:
                    - 99d
                '''
            }
          }
          steps {
            sh 'trivy image --exit-code 1 --severity CRITICAL,HIGH  omerurhan/todos:${commitId}'
          }
        }
      }
    }
    stage('Deploy Kubernetes') {
      agent {
        kubernetes {
          defaultContainer 'kubectl'
          yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: kubectl
                image: alpine/k8s:1.25.0
                command:
                - sleep
                args:
                - 99d
            '''
        }
      }
      steps {
        parallel(
          "Deployment": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
            //sh 'kubectl apply -f kubernetes/sa.yaml'
            sh 'for f in kubernetes/*.yaml; do envsubst < $f | kubectl apply -f -; done'
            }
          },
          "Rollout Status": {
            withKubeConfig([credentialsId: 'kubeconfig']) {
            sh '''
              sleep 30s
              kubectl -n ${namespace} rollout status deploy ${appName} --timeout 5s
              retVal=$?
              if [ $retVal -ne 0 ]; then
                  echo "Deployment ${appName} Rollout has Failed. Rolling back deployment!"
                  kubectl -n ${namespace} rollout undo deploy ${appName}
              fi
              exit $retVal
            '''
            }
          }
        )
      }
     }
    stage ('Integration Test') {
      agent {
        kubernetes {
          defaultContainer 'curl'
          yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: curl
                image: mrnonz/alpine-git-curl
                command:
                - sleep
                args:
                - 99d
            '''
        }
      }
      steps {
        sh '''
        sleep 5s

        http_get_code=$(curl -s -o /dev/null -w "%{http_code}" http://${applicationDNS})
        if [[ "$http_get_code" == 200 ]];
            then
                echo "indexHandler Test Passed"
            else
                echo "indexHandler Test Failed"
                exit 1;
        fi

        http_post_code=$(curl --data-raw 'Item=DEVSECOPS' -L -s -o /dev/null -w "%{http_code}" -H 'Content-Type: application/x-www-form-urlencoded' http://${applicationDNS})
        if [[ "$http_post_code" == 200 ]];
            then
                echo "postHandler Test Passed"
            else
                echo "postHandler Test Failed"
                exit 1;
        fi
        '''
      }
    }
    stage ('OWASP ZAP - DAST') {
      agent {
        kubernetes {
          defaultContainer 'zap'
          yaml '''
            apiVersion: v1
            kind: Pod
            spec:
              containers:
              - name: zap
                image: owasp/zap2docker-weekly
                command:
                - sleep
                args:
                - 99d
                volumeMounts:
                - mountPath: /zap/wrk
                  name: zap-report
              volumes:
              - name: zap-report
                emptyDir:
                  sizeLimit: 500Mi
            '''
        }
      }
      steps {
        sh '''
        mkdir -p owasp-zap-report
        zap-baseline.py -t http://todos.demo.io -r zap_report.html || exit_code=$?
        mv /zap/wrk/zap_report.html owasp-zap-report
        exit 0
        '''
      }
      post {
        always {
          publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML REPORT', reportTitles: 'OWASP ZAP HTML REPORT'])
        }
      }
    }
    stage('Promote to PROD?') {
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
        }
      }
    }
  }
}
