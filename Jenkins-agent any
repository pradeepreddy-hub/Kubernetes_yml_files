pipeline {
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ["$(JENKINS_SECRET)", "$(JENKINS_NAME)"]
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ["/busybox/cat"]
    tty: true
    volumeMounts:
    - name: kaniko-secret
      mountPath: /kaniko/.docker
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  - name: tools
    image: dtzar/helm-kubectl:latest
    command: ["cat"]
    tty: true
    volumeMounts:
    - name: workspace-volume
      mountPath: /home/jenkins/agent

  volumes:
  - name: kaniko-secret
    secret:
      secretName: dockerhub-secret
      items:
      - key: .dockerconfigjson
        path: config.json
  - name: workspace-volume
    emptyDir: {}
  restartPolicy: Never
'''
        }
    }

    environment {
        DOCKER_IMAGE = "docker.io/pradeepreddyhub/hello-world"
        IMAGE_TAG    = "${BUILD_NUMBER}"
        HELM_CHART   = "hello-world"
        HELM_VERSION = "0.2.0"
        JFROG_URL    = "https://trial3sfswa.jfrog.io/artifactory/jenkins-helm"
        KUBE_NS      = "default"
        JFROG_CREDS  = credentials('jfrog-creds')
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/pradeepreddy-hub/Jenkins_docker_hello-world-war.git'
            }
        }

        stage('Build & Push Image') {
            steps {
                container('kaniko') {          // ✅ kaniko for image build only
                    sh '''
                    /kaniko/executor \
                      --dockerfile=Dockerfile \
                      --context=/home/jenkins/agent/workspace/hello-world-war \
                      --destination=$DOCKER_IMAGE:$IMAGE_TAG \
                      --destination=$DOCKER_IMAGE:latest \
                      --skip-tls-verify
                    '''
                }
            }
        }

        stage('Helm Package & Push') {
            steps {
                container('tools') {           // ✅ tools for helm/curl
                    sh '''
                    helm lint $HELM_CHART
                    helm package $HELM_CHART

                    curl -u $JFROG_CREDS_USR:$JFROG_CREDS_PSW \
                      -T ${HELM_CHART}-${HELM_VERSION}.tgz \
                      ${JFROG_URL}/${HELM_CHART}-${HELM_VERSION}.tgz

                    helm repo index . --url ${JFROG_URL}

                    curl -u $JFROG_CREDS_USR:$JFROG_CREDS_PSW \
                      -T index.yaml \
                      ${JFROG_URL}/index.yaml
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('tools') {           // ✅ tools for helm deploy
                    sh '''
                    helm repo add jfrog-helm ${JFROG_URL} \
                      --username $JFROG_CREDS_USR \
                      --password $JFROG_CREDS_PSW \
                      --force-update

                    helm repo update

                    helm upgrade --install $HELM_CHART jfrog-helm/$HELM_CHART \
                      --version $HELM_VERSION \
                      --set image.tag=$IMAGE_TAG \
                      --namespace $KUBE_NS \
                      --wait --timeout 2m
                    '''
                }
            }
        }

        stage('Verify') {
            steps {
                container('tools') {           // ✅ tools for kubectl
                    sh '''
                    kubectl rollout status deployment/$HELM_CHART -n $KUBE_NS
                    kubectl get pods -n $KUBE_NS
                    kubectl get svc -n $KUBE_NS
                    '''
                }
            }
        }
    }

    post {
        success { echo "SUCCESS 🚀" }
        failure { echo "FAILED ❌" }
    }
}
