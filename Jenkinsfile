pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
    // skipDefaultCheckout()  // see 'Checkout SCM' below, once perms are fixed this is no longer needed
  } 

  stages {
    /*
    stage('Checkout SCM') {
      steps {
        sh 'sudo chown -R jenkins:jenkins .'  // bad docker mount creates unreadable files TODO fix this
        deleteDir()  // delete current workspace, for a clean build

        checkout scm
      }
    }
    */

    stage('Test 2.2') {
      environment {
        RUBY_VERSION = '2.2'
      }

      steps {
        sh './test.sh'

        junit 'spec/reports/*.xml, features/reports/*.xml'
      }
    }

    stage('Test 2.3') {
      environment {
        RUBY_VERSION = '2.3'
      }

      steps {
        sh './test.sh'

        junit 'spec/reports/*.xml, features/reports/*.xml'
      }
    }

    stage('Test 2.4') {
      environment {
        RUBY_VERSION = '2.4'
      }

      steps {
        sh './test.sh'

        junit 'spec/reports/*.xml, features/reports/*.xml'
      }
    }
  }

  post {
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}
