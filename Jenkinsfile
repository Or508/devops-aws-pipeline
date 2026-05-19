pipeline {
    agent any

    parameters {
        string(name: 'AWS_KEY_NAME', defaultValue: 'my-aws-key', description: 'Name of the AWS EC2 Key Pair')
    }

    environment {
        AWS_KEY_NAME = "${params.AWS_KEY_NAME}"
    }

    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }
        stage('Terraform Infra Provisioning') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-credentials-id', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    bat '''
                        cd terraform
                        call terraform init
                        call terraform apply -auto-approve -var="aws_key_name=%AWS_KEY_NAME%"
                    '''
                }
            }
        }
        stage('Ansible Configuration & UI Deployment') {
            steps {
                sshagent(credentials: ['ssh-key-id']) {
                    bat '''
                        cd ansible
                        call ansible-playbook -i inventory/inventory.ini playbook.yml
                    '''
                }
            }
        }
    }
}
