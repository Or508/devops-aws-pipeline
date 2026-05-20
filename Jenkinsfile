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
                    [pattern: 'vockey.pem', type: 'EXCLUDE'],
                    [pattern: 'terraform/terraform.tfstate', type: 'EXCLUDE'],
                    [pattern: 'terraform/terraform.tfstate.backup', type: 'EXCLUDE'],
                    [pattern: 'terraform/.terraform/**', type: 'EXCLUDE']
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
                        ..\\terraform.exe apply -auto-approve -no-color -var="aws_key_name=%AWS_KEY_NAME%"
                    '''
                }
            }
        }
        stage('Deploy Application via SSH') {
            steps {
                powershell '''
                    Start-Sleep -Seconds 15
                    
                    # Move to the terraform directory cleanly
                    Set-Location terraform
                    
                    # Use forward slash for the executable to avoid Jenkins escape bugs
                    $TARGET_IP = (../terraform.exe output -no-color -raw instance_public_ip).Trim()
                    
                    # Move back to workspace root
                    Set-Location ..
                    
                    if (-not $TARGET_IP) {
                        Write-Error "Error: Could not fetch Target IP from Terraform!"
                        exit 1
                    }
                    
                    Write-Host "Deploying directly to Target IP: $TARGET_IP"
                    
                    # Run Native SSH and SCP
                    ssh -o StrictHostKeyChecking=no -i "C:/jenkins_keys/vockey.pem" ubuntu@${TARGET_IP} "sudo chown -R ubuntu:ubuntu /var/www/html"
                    scp -o StrictHostKeyChecking=no -r -i "C:/jenkins_keys/vockey.pem" ansible/files/web/* ubuntu@${TARGET_IP}:/var/www/html/
                    
                    Write-Host "Deployment Completed Successfully!"
                '''
            }
        }
    }
}
