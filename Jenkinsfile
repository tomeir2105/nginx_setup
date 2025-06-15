pipeline {
  agent { label 'git-agent' }
  environment {
    DOMAIN = 'example.com'  // Replace or parameterize later
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
    stage('Run vhost.sh') {
      steps {
        sh './vhost.sh $DOMAIN'
      }
    }
  }
}
