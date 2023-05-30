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
    stage('Deploy Kubernetes') {
      agent {
        kubernetes {
          label 'kubectl'
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
        withKubeConfig([credentialsId: 'kubeconfig']) {
          sh 'for f in kubernetes/*.yaml; do envsubst < $f | kubectl apply -f -; done'
          sh 'kubectl rollout status deploy ${appName} -n ${namespace}'
        }
      }
     }

    }
}
