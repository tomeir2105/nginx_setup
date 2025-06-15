pipeline {
  agent { label 'git-agent' }

  environment {
    DOMAIN = 'example.com'  // You can parameterize this later
  }

  stages {
    stage('Install Nginx') {
      steps {
        sh '''
          sudo apt update
          sudo apt install -y nginx
        '''
      }
    }

    stage('Clone Repository') {
      steps {
        git credentialsId: 'github-creds', url: 'https://github.com/tomeir2105/nginx_setup.git'
      }
    }

    stage('Fix Permissions') {
      steps {
        sh 'chmod +x ./vhost.sh'
      }
    }

    stage('Run vhost.sh') {
      steps {
        sh './vhost.sh $DOMAIN'
      }
    }
  }
}
