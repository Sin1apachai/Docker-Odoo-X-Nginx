def gv
def gitToken

def sshServer(CMD, HOST, USERNAME) {
    try {
        command =  """
            sshpass ssh -o StrictHostKeyChecking=no ${USERNAME}@${HOST} '${CMD}'
        """
        sh command
    } catch (Exception e) {
        echo 'Exception occurred: ' + e.toString()
    }
}

pipeline {
    agent any
    parameters {
        string(name: 'PROJECTNAME', defaultValue: '', description: 'PROJECT NAME')
        string(name: 'ADDONS', defaultValue: '', description: 'Addons')
        choice(name: 'ENVIRONMENT', choices: ['','',''], description: 'environment DEPLOY')
        string(name: 'HOST', defaultValue: "", description: 'HOST')
        string(name: 'USERNAME', defaultValue: "", description: 'USERNAME')
        string(name: 'GITID', defaultValue: "", description: 'GITID')
        string(name: 'MODULE', defaultValue: "", description: 'Module Name')
    }
    stages {
        stage("init") {
            steps {
                script {
                    if ("${ENVIRONMENT}" == 'dev')
                    try {
                        echo "Value of PROJECTNAME: ${PROJECTNAME}"
                        echo "Value of ADDONS: ${ADDONS}"
                        echo "Value of ENVIRONMENT: ${ENVIRONMENT}"
                        echo "Value of HOST: ${HOST}"
                        echo "Value of USERNAME: ${USERNAME}"
                        echo "Value of GIT ID: ${GITID}"
                    } catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
        stage("Connect to Server") {
            steps {
                script {
                    try {
                        sshServer("ls -l", host, params.USERNAME)
                        echo "SSH Server Success"
                    } catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
        stage("Git Clone") {
            steps {
                script {
                    try {
                        withCredentials([string(credentialsId: gitid, variable: 'GITTOKEN')]) {
                            sshServer("[ -d /mnt/${PROJECTNAME} ] || git clone https://${GITTOKEN}@github.com/${PROJECTNAME}.git /mnt/${PROJECTNAME}", host, params.USERNAME)
                            echo "Git Clone ${PROJECTNAME} Success"
                            sshServer("[ -d /mnt/addons/${ADDONS} ] || git clone https://${GITTOKEN}@github.com/${ADDONS}.git /mnt/addons/${ADDONS}", host, params.USERNAME)
                        }
                        echo "Git Clone Addons Success"
                    } catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
        stage("Git Pull Origin") {
            steps {
                script {
                    try {
                        echo "Git URL: ${env.GIT_URL}"
                        echo "Git Branch: ${env.GIT_BRANCH}"
                        withCredentials([string(credentialsId: gitid, variable: 'GITTOKEN')]) {
                            sshServer("""
                                cd /mnt/${PROJECTNAME} &&
                                git reset --hard &&
                                git remote set-url origin https://${GITTOKEN}@github.com/${PROJECTNAME}.git && 
                                git pull origin && 
                                git remote set-url origin https://github.com/${PROJECTNAME}.git
                                """,
                            params.HOST, params.USERNAME)
                            echo "Git Pull ${PROJECTNAME} Success"
                        }
                        withCredentials([string(credentialsId: gitid, variable: 'GITTOKEN')]) {
                            sshServer("""
                                cd /mnt/addons/${ADDONS} && 
                                git remote set-url origin https://${GITTOKEN}@github.com/${ADDONS}.git && 
                                git pull origin && 
                                git remote set-url origin https://github.com/${ADDONS}.git
                                """,
                            params.HOST, params.USERNAME)
                            echo "Git Pull Addons Success"
                        }
                    } catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
        stage("Edit Configuration Path") {
            steps {
                script {
                    try {
                        cmd = """
                                sed -i "s|addons_path\\s*=.*|&${'\$'}(find /mnt/addons/${ADDONS} -maxdepth 1 -mindepth 1 -type d ! -name '.git' -printf ',%p')|" /mnt/${PROJECTNAME}/config/odoo.conf
                            """
                        echo cmd
                        sshServer(cmd, params.HOST, params.USERNAME)
                        echo "EDIT Config Success"
                    } catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
        stage("Docker Build") {
            steps {
                script {
                    try {
                        cmd = """
                                cd /mnt/${PROJECTNAME} &&
                                docker build . -t mink --no-cache &&
                                docker-compose down &&
                                docker rmi ${'\$'}(docker images -f "dangling=true" -q)
                            """
                        echo cmd
                        sshServer(cmd, params.HOST, params.USERNAME)
                        echo "Docker Build Success"
                    } catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
        stage("Deploy Application") {
            steps {
                script {
                    try {
                        echo "deploying"
                        if ("${MODULE}" != ""){
                            sshServer("""
                                cd /mnt/${PROJECTNAME} && COMPOSE_OPTIONS=\"--update=${MODULE}\" docker-compose up -d
                            """, host, params.USERNAME)
                        }
                        else {
                            sshServer("""
                                cd /mnt/${PROJECTNAME} && docker-compose up -d
                            """, host, params.USERNAME)
                        }
                        echo "Deploy Success"
                    } catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                        currentBuild.result = 'FAILURE'
                    }
                }
            }
        }
    }   
}
