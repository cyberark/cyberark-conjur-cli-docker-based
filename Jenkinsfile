#!/usr/bin/env groovy

pipeline {
  agent { label 'executor-v2' }

  options {
    timestamps()
    buildDiscarder(logRotator(daysToKeepStr: '30'))
  }

  triggers {
    cron(getDailyCronString())
  }

  stages {
    stage('Validate Changelog') {
      steps { parseChangelog() }
    }

    stage('Prepare CC Report Dir'){
      steps {
        script {
          ccCoverage.dockerPrep()
          sh 'mkdir -p coverage'
        }
      }
    }

    stage('Test Ruby 3.1') {
      environment {
        RUBY_VERSION = '3.1'
      }

      steps {
        sh './test.sh'
      }

      post {
        always {
          junit 'spec/reports/*.xml, features/reports/*.xml'
        }
      }
    }

    stage('Test Ruby 3.0') {
      environment {
        RUBY_VERSION = '3.0'
      }

      steps {
        sh './test.sh'
      }

      post {
        always {
          junit 'spec/reports/*.xml, features/reports/*.xml'
        }
      }
    }

    stage('Submit Coverage Report'){
      steps{
        sh 'ci/submit-coverage'
        publishHTML([reportDir: 'coverage', reportFiles: 'index.html', reportName: 'Coverage Report', reportTitles: '', allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true])
      }

      post {
        always {
          archiveArtifacts artifacts: "coverage/.resultset.json", fingerprint: false
        }
      }
    }

    stage('Build standalone image') {
      steps {
        sh './build-standalone'
      }
    }

    stage('Scan Docker image') {
      parallel {
        stage('Scan Docker image for fixable vulns') {
          steps {
            scanAndReport("cyberark/conjur-cli:latest", "HIGH", false)
          }
        }
        stage('Scan Docker image for total vulns') {
          steps {
            scanAndReport("cyberark/conjur-cli:latest", "NONE", true)
          }
        }
      }
    }

    stage('Push standalone image to DockerHub') {
      when { tag "v*" }

      steps {
        sh './push-image'
      }
    }

    // Only publish to RubyGems if the HEAD is
    // tagged with the same version as in version.rb
    stage('Publish to RubyGems') {
      when {
        expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
        tag "v*"
      }

      steps {
        // Clean up first
        sh 'git clean -fxd'

        sh './publish.sh'

        // Clean up again...
        sh 'git clean -fxd'
        deleteDir()
      }
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}
