pipeline {
    agent any
    
    environment {
        AWS_KEY_NAME = "${params.AWS_KEY_NAME}"
    }
    
    parameters {
        string(name: 'AWS_KEY_NAME', defaultValue: 'vockey', description: 'Name of the AWS EC2 Key Pair')
    }
    
    stages {
        stage('Checkout') {
            steps {
                cleanWs(deleteDirs: true, patterns: [
                    [pattern: 'terraform.exe', type: 'EXCLUDE'],
                    [pattern: 'vockey.pem', type: 'EXCLUDE']
                ])
                checkout scm
            }
        }
        stage('Terraform Infra Provisioning') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-credentials-id', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat '''
                        cd terraform
                        ..\\terraform.exe init
                        ..\\terraform.exe apply -auto-approve -var="aws_key_name=%AWS_KEY_NAME%"
                    '''
                }
            }
        }
        stage('Ansible Configuration & UI Deployment') {
            steps {
                bat '''
                    cd ansible
                    wsl -d Ubuntu chmod 400 ../vockey.pem
                    wsl -d Ubuntu ansible-playbook -i inventory/inventory.ini playbook.yml --private-key=../vockey.pem
                '''
            }
        }
    }
}
