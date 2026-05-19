pipeline {
  agent any

  parameters {
    string(
      name: 'AWS_KEY_NAME',
      defaultValue: 'redux-movie-key',
      description: 'AWS EC2 Key Pair name (must match public key for Jenkins credential ssh-key-id)'
    )
    string(
      name: 'AWS_REGION',
      defaultValue: 'us-east-1',
      description: 'AWS region for Terraform'
    )
  }

  environment {
    TF_DIR            = 'terraform'
    ANSIBLE_DIR       = 'ansible'
    INVENTORY_FILE    = 'ansible/inventory/inventory.ini'
    ANSIBLE_USER      = 'ubuntu'
    ANSIBLE_SSH_OPTS  = '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR'
    HEALTH_CHECK_URL  = '' // set after Terraform apply
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Plan & Apply') {
      steps {
        // Jenkins: "Username with password" — Username = AWS Access Key ID, Password = Secret Access Key
        withCredentials([
          usernamePassword(
            credentialsId: 'aws-credentials-id',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
          )
        ]) {
          dir(env.TF_DIR) {
            sh """
              set -e
              export AWS_DEFAULT_REGION='${params.AWS_REGION}'
              export AWS_REGION='${params.AWS_REGION}'
              terraform init -input=false
              terraform validate
              terraform plan -input=false -out=tfplan \\
                -var='aws_key_name=${params.AWS_KEY_NAME}' \\
                -var='aws_region=${params.AWS_REGION}' \\
                -var='ansible_ssh_user=${ANSIBLE_USER}'
              terraform apply -input=false -auto-approve tfplan
            """
          }
        }
      }
    }

    stage('Export Terraform Outputs') {
      steps {
        dir(env.TF_DIR) {
          script {
            env.TF_PUBLIC_IP = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
            env.TF_KEY_NAME  = sh(script: 'terraform output -raw aws_key_name', returnStdout: true).trim()
            env.HEALTH_CHECK_URL = "http://${env.TF_PUBLIC_IP}/"

            def inventoryPath = sh(script: 'terraform output -raw ansible_inventory_file', returnStdout: true).trim()
            echo "Generated inventory: ${inventoryPath}"
            sh "cat '${inventoryPath}'"

            if (env.TF_KEY_NAME != params.AWS_KEY_NAME) {
              error("Key pair mismatch: EC2='${env.TF_KEY_NAME}' vs parameter='${params.AWS_KEY_NAME}'")
            }
          }
        }
      }
    }

    stage('Ansible Deploy') {
      steps {
        sshagent(credentials: ['ssh-key-id']) {
          sh """
            set -e
            export ANSIBLE_HOST_KEY_CHECKING=False

            if [ ! -f '${INVENTORY_FILE}' ]; then
              echo "Missing inventory: ${INVENTORY_FILE}" >&2
              exit 1
            fi

            echo "Waiting for SSH on ${TF_PUBLIC_IP} (user: ${ANSIBLE_USER})..."
            for i in \$(seq 1 36); do
              if ssh \${ANSIBLE_SSH_OPTS} -o ConnectTimeout=5 -o BatchMode=yes \\
                ${ANSIBLE_USER}@${TF_PUBLIC_IP} "echo ok" 2>/dev/null; then
                echo "SSH ready."
                break
              fi
              if [ "\$i" -eq 36 ]; then
                echo "SSH timeout." >&2
                exit 1
              fi
              sleep 10
            done

            ansible-playbook \\
              -i '${INVENTORY_FILE}' \\
              '${ANSIBLE_DIR}/playbook.yml' \\
              -u '${ANSIBLE_USER}' \\
              --extra-vars "ansible_ssh_common_args='\${ANSIBLE_SSH_OPTS}'"
          """
        }
      }
    }

    stage('Health Check') {
      steps {
        sh """
          set -e
          URL='${HEALTH_CHECK_URL}'
          echo "Sanity check: \${URL}"
          for i in \$(seq 1 24); do
            HTTP_CODE=\$(curl -sS -o /tmp/site_check.html -w '%{http_code}' --max-time 15 "\${URL}" || echo "000")
            if [ "\${HTTP_CODE}" = "200" ]; then
              echo "SUCCESS — HTTP 200 from \${URL}"
              grep -q 'Movie Nexus' /tmp/site_check.html && echo "Content verified: Movie Nexus landing page detected."
              exit 0
            fi
            echo "Attempt \$i: HTTP \${HTTP_CODE} — retrying in 10s..."
            sleep 10
          done
          echo "Health check failed for \${URL}" >&2
          exit 1
        """
      }
    }
  }

  post {
    success {
      echo "Deployment verified → ${env.HEALTH_CHECK_URL}"
    }
    failure {
      echo 'Pipeline failed. Credentials: aws-credentials-id (Access Key/Secret), ssh-key-id (ubuntu user).'
    }
  }
}
