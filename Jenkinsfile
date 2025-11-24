pipeline {
    agent any

    stages {
        // ──────────────────────────────────────────────────────────────
        // 1. LẤY CODE MỚI NHẤT TỪ GITHUB
        // ──────────────────────────────────────────────────────────────
        stage('Checkout Source Code') {
            steps {
                checkout scm
                echo "Đã lấy code mới nhất từ GitHub"
            }
        }

        // ──────────────────────────────────────────────────────────────
        // 2. BUILD DOCKER IMAGE + ĐẨY LÊN ECR
        // ──────────────────────────────────────────────────────────────
        stage('Build Docker Image & Push to ECR') {
            steps {
                script {
                    def buildTag   = "${env.BUILD_NUMBER}"
                    def ecrRepo    = "cp-ecr"
                    def region     = "ap-northeast-2"
                    def accountId  = "591313757404"

                    // Đăng nhập ECR
                    sh "aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${accountId}.dkr.ecr.${region}.amazonaws.com"

                    // Build + tag + push
                    sh "docker build -t ${ecrRepo}:${buildTag} ."
                    sh "docker tag ${ecrRepo}:${buildTag} ${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"
                    sh "docker push ${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"

                    echo "Đã đẩy image thành công: ${ecrRepo}:${buildTag}"
                    env.IMAGE_URI = "${accountId}.dkr.ecr.${region}.amazonaws.com/${ecrRepo}:${buildTag}"
                }
            }
        }

        // ──────────────────────────────────────────────────────────────
        // 3. TỰ ĐỘNG TẠO TASK DEFINITION MỚI + DEPLOY (QUAN TRỌNG NHẤT)
        // → Fix triệt để vấn đề digest cũ, đảm bảo luôn pull image mới
        // ──────────────────────────────────────────────────────────────
        stage('Update Task Definition & Deploy to ECS') {
            steps {
                script {
                    def taskFamily   = "taskcongphuc"      // TÊN FAMILY CỦA BẠN (xem trong ECS → Task Definitions)
                    def clusterName  = "cp-cluster"
                    def serviceName  = "cp-sv"
                    def region       = "ap-northeast-2"

                    // 1. Lấy task definition hiện tại làm template
                    sh "aws ecs describe-task-definition --task-definition ${taskFamily} --region ${region} --query 'taskDefinition' > current-task.json"

                    // 2. Thay thế image bằng tag mới nhất (dùng sed, không cần jq)
                    sh "perl -pi -e 's|\"image\": \".*\"|\"image\": \"${env.IMAGE_URI}\"|g' current-task.json"

                    // 3. Register revision mới (revision tự tăng)
                    def newTaskArn = sh(
                        script: """
                            aws ecs register-task-definition \
                                --cli-input-json file://current-task.json \
                                --family ${taskFamily} \
                                --region ${region} \
                                --query 'taskDefinition.taskDefinitionArn' \
                                --output text
                        """,
                        returnStdout: true
                    ).trim()

                    echo "Đã tạo Task Definition mới: ${newTaskArn}"

                    // 4. Update service để dùng task definition mới + force deploy
                    sh """
                        aws ecs update-service \
                            --cluster ${clusterName} \
                            --service ${serviceName} \
                            --task-definition ${newTaskArn} \
                            --force-new-deployment \
                            --region ${region}
                    """

                    // Dọn dẹp file tạm
                    sh "rm -f current-task.json"

                    echo "HOÀN TẤT DEPLOY! Image đang chạy: ${env.IMAGE_URI}"
                    echo "Web sẽ cập nhật trong vòng 1-2 phút"
                }
            }
        }
    }

    post {
        success {
            echo "CI/CD THÀNH CÔNG 100%! Web đã được cập nhật phiên bản mới nhất"
        }
        failure {
            echo "CÓ LỖI XẢY RA – Xem log để sửa nhé!"
        }
    }
}
