pipeline {
  agent { label 'git-agent' }

  parameters {
    string(name: 'DOMAIN_NAME', defaultValue: 'example.com', description: 'Enter the domain name to configure')
  }

  environment {
    DOMAIN = "${params.DOMAIN_NAME}"
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
        sh "./vhost.sh $DOMAIN"
      }
    }
  }
}
