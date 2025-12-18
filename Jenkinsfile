pipeline {
    agent any

    environment {
        TF_IN_AUTOMATION = 'true'
        TF_CLI_ARGS = '-no-color'
        SSH_CRED_ID = 'aws-deployer-ssh-key'
        // We will bind AWS credentials inside the stages to avoid the binding warning
    }

    stages {
        stage('Terraform Initialization') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'AWS_pranav', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    // -reconfigure fixes the "Backend configuration changed" error
                    sh 'terraform init -reconfigure'
                    sh "cat ${env.BRANCH_NAME}.tfvars"
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'AWS_pranav', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh "terraform plan -var-file=${env.BRANCH_NAME}.tfvars"
                }
            }
        }

        stage('Validate Apply') {
            input {
                message "Do you want to apply this plan?"
                ok "Apply"
            }
            steps {
                echo 'Apply Accepted'
            }
        }

        stage('Terraform Provisioning') {
            steps {
                script {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding', 
                        credentialsId: 'AWS_pranav', 
                        accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                    ]]) {
                        // Fixed string interpolation with double quotes
                        sh "terraform apply -auto-approve -var-file=${env.BRANCH_NAME}.tfvars"

                        // Extract Outputs
                        env.INSTANCE_IP = sh(script: 'terraform output -raw instance_public_ip', returnStdout: true).trim()
                        env.INSTANCE_ID = sh(script: 'terraform output -raw instance_id', returnStdout: true).trim()

                        echo "Provisioned Instance IP: ${env.INSTANCE_IP}"
                        echo "Provisioned Instance ID: ${env.INSTANCE_ID}"
                        
                        sh "echo '${env.INSTANCE_IP}' > dynamic_inventory.ini"
                    }
                }
            }
        }

        stage('Wait for AWS Instance Status') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'AWS_pranav', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    echo "Waiting for instance ${env.INSTANCE_ID} to pass AWS health checks..."
                    sh "aws ec2 wait instance-status-ok --instance-ids ${env.INSTANCE_ID} --region us-east-1"
                }
            }
        }

        stage('Validate Ansible') {
            input {
                message "Do you want to run Ansible?"
                ok "Run Ansible"
            }
            steps {
                echo 'Ansible approved'
            }
        }

        stage('Ansible Configuration') {
            steps {
                // The Ansible plugin handles its own credential injection for SSH
                ansiblePlaybook(
                    playbook: 'playbooks/grafana.yml',
                    inventory: 'dynamic_inventory.ini', 
                    credentialsId: "${SSH_CRED_ID}"
                )
            }
        }

        stage('Validate Destroy') {
            input {
                message "Do you want to destroy?"
                ok "Destroy"
            }
            steps {
                echo 'Destroy Approved'
            }
        }

        stage('Destroy') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding', 
                    credentialsId: 'AWS_pranav', 
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars"
                }
            }
        }
    }

    post {
        always {
            sh 'rm -f dynamic_inventory.ini'
        }
        failure {
            withCredentials([[
                $class: 'AmazonWebServicesCredentialsBinding', 
                credentialsId: 'AWS_pranav', 
                accessKeyVariable: 'AWS_ACCESS_KEY_ID', 
                secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
            ]]) {
                // Attempt cleanup only if init was successful enough to run destroy
                sh "terraform destroy -auto-approve -var-file=${env.BRANCH_NAME}.tfvars || echo 'Manual cleanup required.'"
            }
        }
    }
}