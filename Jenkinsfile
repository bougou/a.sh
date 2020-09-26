pipeline {
  agent any


  environment {
    // Jenkins does not include /usr/local/bin in the PATH
    PATH="/usr/local/bin:$PATH"

    PROJECT_EMOJI = '🚢'
  }

  stages {
    stage('NOCI check') {
      steps {
        abortPreviousBuilds()

        noci action: 'check'

        load_envs_common()
      }
    }

    stage('Print information') {
      steps {
        printInformation()
      }
    }


    stage('Build') {
      steps {
        script {
          sendNotifications("INFO", "Upload a.sh")

          sh """
            s3cmd -c \$HOME/.s3cfg.qiniu put --acl-public a.sh s3://bougou/

            echo "\nhttp://bougou.42cloud.com/a.sh" >> ${env.BUILD_OUTPUT_FILE}
          """
        }
      }
    }

    stage('Capture Output') {
      steps {
        captureBuildOutput()
      }
    }

  }

  post {
    always {
      noci action: 'postProcess'
    }

    aborted {
      sendNotifications("ABORTED", "Build aborted")
    }

    unstable {
      sendNotifications("UNSTABLE", "Build unstable")
    }

    success {
      sendNotifications("SUCCESS", "Build succeed", "${env.build_output}")
    }

    failure {
      sendNotifications("FAILURE", "Build failed")
    }
  }
}
