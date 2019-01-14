#!/groovy

node('node1') {
    stage('Syntax Testing') {
	deleteDir()
        checkout scm
        try {
            sh '/usr/local/bin/rubocop ./cookbooks --fail-level E -f s'
        }
        catch (Exception ex) {       
            mail from: "jenkins_admin@jenkins.dev.net",       
            to: "boardstretcher@github.com",       
            subject: "jenkins chef orchestration syntax check FAILED",       
            body: "syntax_testing section (rubocop)... build number: ${env.BUILD_NUMBER}"       
            throw ex   
        }
    }
}

node('node1') {
    stage('Stash Configs') {
	deleteDir()
        checkout scm
        stash excludes: '**/.*,_vagrant/**', name: 'configs'
    }
}

remote1: {
    node('node2') {
        stage('remote1') {
            deleteDir()
            unstash 'configs'
            def work_dir = pwd()
        }
    }
}
