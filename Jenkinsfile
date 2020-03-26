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
      steps { sh './bin/parse-changelog.sh' }
    }

    stage('Prepare CC Report Dir') {
      steps {
        script {
          ccCoverage.dockerPrep()
          sh 'mkdir -p coverage'
        }
      }
    }

    stage('Run Tests') {
      parallel {
        stage('Test 2.4') {
          environment {
            RUBY_VERSION = '2.4'
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

        stage('Test 2.5') {
          environment {
            RUBY_VERSION = '2.5'
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

        stage('Test 2.6') {
          environment {
            RUBY_VERSION = '2.6'
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

    stage('Publish') {
      parallel {
        stage('Push standalone image to DockerHub') {
          when {
            branch 'master'
          }

          steps {
            sh './push-image'
          }
        }

        // Only publish to RubyGems if the HEAD is
        // tagged with the same version as in version.rb
        stage('Publish to RubyGems') {
          agent { label 'releaser-v2' }

          when {
            expression { currentBuild.resultIsBetterOrEqualTo('SUCCESS') }
            branch "master"
            expression {
              def exitCode = sh returnStatus: true, script: './needs-publishing'
              return exitCode == 0
            }
          }

          steps {
            // Clean up first
            sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'

            sh './publish.sh'

            // Clean up again...
            sh 'docker run -i --rm -v $PWD:/src -w /src alpine/git clean -fxd'
            deleteDir()
          }
        }
      }
    }
  }

  post {
    always {
      cleanupAndNotify(currentBuild.currentResult)
    }
  }
}
