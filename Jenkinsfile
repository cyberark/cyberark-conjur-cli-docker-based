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

    stage('Build standalone Docker image') {
      steps {
        sh './build-standalone'
      }
    }

    stage('Publish standalone Docker image to DockerHub') {
      steps {
        sh './push-image'
      }
    }

    // Only publish to RubyGems if the HEAD is
    // tagged with the same version as in version.rb
    stage('Publish to RubyGems') {
      agent { label 'releaser-v2' }

      when {
        expression {
          def exitCode = sh returnStatus: true, script: ''' set +x
            echo "Determining if publishing is requested..."

            VERSION=`cat lib/conjur/version.rb | grep \'VERSION\\s*=\' | sed -e "s/.*\'\\(.*\\)\'.*/\\1/"`
            echo Declared version: $VERSION

            # Jenkins git plugin is broken and always fetches with `--no-tags`
            # (or `--tags`, neither of which is what you want), so tags end up
            # not being fetched. Try to fix that.
            # (Unfortunately this fetches all remote heads, so we may have to find
            # another solution for bigger repos.)
            git fetch -q

            # note when tag not found git rev-parse will just print its name
            TAG=`git rev-parse tags/v$VERSION 2>/dev/null || :`
            echo Tag v$VERSION: $TAG

            HEAD=`git rev-parse HEAD`
            echo HEAD: $HEAD

            test "$HEAD" = "$TAG"
          '''
          return exitCode == 0
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
