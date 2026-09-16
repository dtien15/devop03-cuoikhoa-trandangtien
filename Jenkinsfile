// ============================================================
//  JENKINS PIPELINE - MERN Todo App
//  Jenkins chay bang container tren chinh VPS, co mount
//  /var/run/docker.sock va /opt/todo-app nen deploy truc tiep.
//
//  Credentials can tao trong Jenkins:
//    - ghcr-credentials  (Username with password: username GitHub / PAT co write:packages)
//  Environment variable can dat (Manage Jenkins > System):
//    - APP_DOMAIN = todo.muatheme247.com
// ============================================================

pipeline {
    agent any

    environment {
        REGISTRY        = 'ghcr.io'
        REGISTRY_OWNER  = 'dtien15'
        IMAGE_PREFIX    = "ghcr.io/dtien15/devop03-cuoikhoa-trandangtien"
        APP_DIR         = '/opt/todo-app'
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        APP_DOMAIN      = "${env.APP_DOMAIN ?: 'todo.muatheme247.com'}"
    }

    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '15'))
        disableConcurrentBuilds()
    }

    triggers {
        // Cho GitHub goi webhook, hoac poll moi 5 phut neu khong dung webhook
        pollSCM('H/5 * * * *')
    }

    stages {

        stage('1. Lay ma nguon') {
            steps {
                checkout scm
                sh 'git log -1 --pretty="%h %an %s"'
            }
        }

        stage('2. Kiem tra ma nguon') {
            parallel {
                stage('Backend') {
                    steps {
                        // Khong dung -v <workspace>:/app duoc: duong dan sau -v la duong dan
                        // TREN HOST, ma jenkins_home la named volume nen host khong co
                        // duong dan do -> Docker tao thu muc rong, npm bao thieu package.json.
                        // Giai phap: bom ma nguon vao container qua stdin bang tar.
                        sh '''
                            tar -cf - backend | docker run --rm -i node:20-alpine sh -c '
                                mkdir -p /src && tar -xf - -C /src && cd /src/backend &&
                                npm install --no-audit --no-fund > /dev/null 2>&1 &&
                                for f in $(find . -name "*.js" -not -path "./node_modules/*"); do
                                    node --check "$f" || exit 1
                                done &&
                                echo "Cu phap backend OK"
                            '
                        '''
                    }
                }
                stage('Docker Compose') {
                    steps {
                        sh 'docker compose -f docker-compose.yml config -q && echo "docker-compose.yml OK"'
                        // File monitoring khong tu dinh nghia network todo-net,
                        // phai ghep voi file chinh moi validate duoc.
                        sh '''
                            docker compose -f docker-compose.yml                                            -f docker-compose.monitoring.yml config -q
                            echo "docker-compose.monitoring.yml OK"
                        '''
                    }
                }
            }
        }

        stage('3. Build image') {
            parallel {
                stage('backend') {
                    steps {
                        sh """
                            docker build \
                                -t ${IMAGE_PREFIX}-backend:${IMAGE_TAG} \
                                -t ${IMAGE_PREFIX}-backend:latest \
                                ./backend
                        """
                    }
                }
                stage('frontend') {
                    steps {
                        sh """
                            docker build \
                                --build-arg REACT_APP_API_URL=/api \
                                -t ${IMAGE_PREFIX}-frontend:${IMAGE_TAG} \
                                -t ${IMAGE_PREFIX}-frontend:latest \
                                ./frontend
                        """
                    }
                }
            }
        }

        stage('4. Day image len GHCR') {
            when {
                anyOf {
                    branch 'main'
                    // Job Pipeline thuong (khong phai Multibranch) khong co
                    // bien BRANCH_NAME -> dieu kien branch luon sai va stage
                    // bi bo qua. Nhanh nay xu ly truong hop do.
                    expression { env.BRANCH_NAME == null }
                }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'ghcr-credentials',
                    usernameVariable: 'GHCR_USER',
                    passwordVariable: 'GHCR_TOKEN'
                )]) {
                    sh '''
                        echo "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USER" --password-stdin
                    '''
                    sh """
                        docker push ${IMAGE_PREFIX}-backend:${IMAGE_TAG}
                        docker push ${IMAGE_PREFIX}-backend:latest
                        docker push ${IMAGE_PREFIX}-frontend:${IMAGE_TAG}
                        docker push ${IMAGE_PREFIX}-frontend:latest
                    """
                }
            }
        }

        stage('5. Deploy len VPS') {
            when {
                anyOf {
                    branch 'main'
                    // Job Pipeline thuong (khong phai Multibranch) khong co
                    // bien BRANCH_NAME -> dieu kien branch luon sai va stage
                    // bi bo qua. Nhanh nay xu ly truong hop do.
                    expression { env.BRANCH_NAME == null }
                }
            }
            steps {
                sh """
                    cd ${APP_DIR}
                    git fetch --all && git reset --hard origin/main
                    docker compose -f docker-compose.prod.yml pull backend frontend
                    docker compose -f docker-compose.prod.yml \
                                   -f docker-compose.monitoring.yml \
                                   up -d --remove-orphans
                """
            }
        }

        stage('6. Kiem tra sau deploy') {
            when {
                anyOf {
                    branch 'main'
                    // Job Pipeline thuong (khong phai Multibranch) khong co
                    // bien BRANCH_NAME -> dieu kien branch luon sai va stage
                    // bi bo qua. Nhanh nay xu ly truong hop do.
                    expression { env.BRANCH_NAME == null }
                }
            }
            steps {
                sh """
                    cd ${APP_DIR}
                    for i in \$(seq 1 20); do
                        if docker compose -f docker-compose.prod.yml exec -T backend \
                             wget -qO- http://127.0.0.1:8000/health | grep -q '"status":"ok"'; then
                            echo "Backend healthy"
                            exit 0
                        fi
                        echo "Cho backend... (\$i/20)"
                        sleep 5
                    done
                    echo "Backend khong healthy sau khi deploy"
                    exit 1
                """
                sh """
                    code=\$(curl -s -o /dev/null -w '%{http_code}' https://${APP_DOMAIN} || true)
                    echo "Trang chu tra ve HTTP \$code"
                """
            }
        }
    }

    post {
        success {
            echo "Build #${env.BUILD_NUMBER} thanh cong - https://${APP_DOMAIN}"
        }
        failure {
            echo "Build #${env.BUILD_NUMBER} THAT BAI - xem log o tren"
            sh """
                cd ${APP_DIR} 2>/dev/null && \
                docker compose -f docker-compose.prod.yml logs --tail=50 backend || true
            """
        }
        always {
            sh 'docker image prune -f || true'
            cleanWs()
        }
    }
}
