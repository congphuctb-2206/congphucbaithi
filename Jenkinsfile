pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                echo "Đã lấy code mới nhất"
            }
        }

        stage('Build & Push ECR') {
            steps {
                script {
                    def tag = "${env.BUILD_NUMBER}"
                    def repo = "cp-ecr"
                    def account = "591313757404"
                    def region = "ap-northeast-2"

                    sh """
                        aws ecr get-login-password --region ${region} \
                        | docker login --username AWS --password-stdin ${account}.dkr.ecr.${region}.amazonaws.com

                        docker build -t ${repo}:${tag} .
                        docker tag ${repo}:${tag} ${account}.dkr.ecr.${region}.amazonaws.com/${repo}:${tag}
                        docker push ${account}.dkr.ecr.${region}.amazonaws.com/${repo}:${tag}
                    """

                    env.IMAGE_URI = "${account}.dkr.ecr.${region}.amazonaws.com/${repo}:${tag}"
                    echo "Push xong image: ${env.IMAGE_URI}"
                }
            }
        }

        stage('Deploy to ECS') {
            steps {
                script {
                    def family  = "taskcongphuc"
                    def cluster = "cp-cluster"
                    def service = "cp-sv"
                    def region  = "ap-northeast-2"

                    // Xuất task definition cũ
                    sh """
                        aws ecs describe-task-definition \
                            --task-definition ${family} \
                            --region ${region} \
                            --query 'taskDefinition' > old.json
                    """

                    // Tạo task definition mới (LOẠI BỎ TAGS ĐỂ KHÔNG LỖI)
                    sh """
                        cat old.json | jq '{
                            family: .family,
                            networkMode: .networkMode,
                            taskRoleArn: .taskRoleArn,
                            executionRoleArn: .executionRoleArn,
                            containerDefinitions: .containerDefinitions,
                            volumes: (.volumes // []),
                            placementConstraints: (.placementConstraints // []),
                            requiresCompatibilities: (.requiresCompatibilities // ["FARGATE"]),
                            cpu: .cpu,
                            memory: .memory,
                            runtimePlatform: .runtimePlatform
                        } | .containerDefinitions[0].image = "${env.IMAGE_URI}"' > new-task.json
                    """

                    // Đăng ký task mới
                    def taskArn = sh(
                        script: """
                            aws ecs register-task-definition \
                                --cli-input-json file://new-task.json \
                                --region ${region} \
                                --query 'taskDefinition.taskDefinitionArn' \
                                --output text
                        """,
                        returnStdout: true
                    ).trim()

                    echo "Task Definition mới: ${taskArn}"

                    // Update ECS service
                    sh """
                        aws ecs update-service \
                            --cluster ${cluster} \
                            --service ${service} \
                            --task-definition ${taskArn} \
                            --force-new-deployment \
                            --region ${region}
                    """

                    sh "rm -f old.json new-task.json"
                    echo "DEPLOY XONG 100% – ECS đang chạy phiên bản mới!"
                }
            }
        }
    }

    post {
        success { echo "CI/CD HOÀN HẢO – Triển khai ECS thành công!" }
        failure { echo "Có lỗi rồi bạn ơi, gọi mình hỗ trợ ngay nhé!" }
    }
}
