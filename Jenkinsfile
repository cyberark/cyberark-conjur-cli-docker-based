pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  } 

  stages {

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

    stage('Build deb') {
      steps {
        sh './build-deb.sh'
        
        archiveArtifacts artifacts: '*.deb', fingerprint: true
      }
    }

    stage('Publish deb') {
      when {
        branch 'master'
      }

      steps {
        sh './publish.sh conjurtools stable'
      }
    }

  }

  post {
    always {
      sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'
    }      
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}
