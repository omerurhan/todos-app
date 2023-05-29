pipeline {
  agent any
    environment {
        namespace = "dev"
        appName = "todos"
        commitId = "${sh(script:'git rev-parse --short HEAD', returnStdout: true)}"
        applicationDNS = "todos.demo.io"
    }
    stages {
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
    }
}