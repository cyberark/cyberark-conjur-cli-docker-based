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
        archiveArtifacts "tmp/deb/*"
      }
    }

    stage('Publish deb') {
      when {
        branch 'v4'
      }

      steps {
        sh './publish-deb.sh $(cat APPLIANCE_VERSION) stable'
      }
    }

    // Only publish to RubyGems if branch is 'master'
    // AND someone confirms this stage within 5 minutes
    stage('Publish to RubyGems?') {
      agent { label 'releaser-v2' }

      when {
        allOf {
          branch 'v4'
          expression {
            boolean publish = false
            try {
              timeout(time: 5, unit: 'MINUTES') {
                input(message: 'Publish to RubyGems?')
                publish = true
              }
            } catch (final ignore) {
              publish = false
            }
            return publish
          }
        }
      }
      steps {
        checkout scm
        sh './publish-rubygem.sh'
        deleteDir()
      }
    }
  }

  post {
    always {
      sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'
      deleteDir()
    }
    failure {
      slackSend(color: 'danger', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} FAILURE (<${env.BUILD_URL}|Open>)")
    }
    unstable {
      slackSend(color: 'warning', message: "${env.JOB_NAME} #${env.BUILD_NUMBER} UNSTABLE (<${env.BUILD_URL}|Open>)")
    }
  }
}
