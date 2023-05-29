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
    }
}