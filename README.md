Git repo "final-project" includes following files: 
  * main.tf
  * outputs.tf
  * variables.tf
  * Jenkinsfile
  * flask-app.yaml
  * mysql.yaml

**Description**: 
1. main.tf:
   The file installs:
     * Provider AWS
     * New VPC from module
     * Creates new roles for eks and jennkins
     * Creates new policy and attaches policies to the relevant roles
     * Creates new Security Group
     * Creates new EC2 instance
     * Installs on the instance with Bash commands the following:
         a. Java
         b. AWS CLI
         c. Kubectl
         d. Eksctl
         e. Jenkins (runs on EC2 public IP, port 8080)
     * Creates EKS cluster with 2 nodes, with auto load balancer. 

2. outputs.tf:
   The file shows in output:
     * Cluster endpoint - external IP
     * Cluster kubeconfig command
     * EC2 instance public IP
     * Jenkins EC2 instance initial password - needed to login to Jenkins.  

3. variables.tf:
   The file has variables for the main.tf
     * Note: variable "key_name" needs to be replaced with your own .pem key.
  
4. Jenkinsfile:
   The file includes a pipeline for the Jenkins that will clone files from git and will deploy the Contacts web app on the EKS cluster.
     * Note: in Jenkins, need to add your AWS credentials as a secret text type. Both aws_access_key_id and aws_secret_access_key.
   The pipeline clone the git, update the Kubernetes context in config file, will configure the AWS credentials and then will deploy the web app.

5. flask-app.yaml:
   Runs the Contacts app on the cluster and can be accessible via the external IP of the cluster, port 5000.
   The web app uses docker image.  

7. mysql.yaml:
   Provisions mysql service that will store the web app data in its db.

**Actions**: 

1. Clone git with the files.
2. Get AWS key pair .pem file and place it in the same library.
3. Run terraform init, plan and apply (Terraform needs to be installed). 
4. Terraform will create number of objects in AWS (this can take some time). 
5. Use the ec2 instance IP with port 8080 to launch Jenkins.
6. Use the Jenkins initial password to login.
7. Install the initially suggested plugins.
8. In Manage Jenkins add Credentials for access key id and for secret access key.
9. Create new pipeline in Jenkins, using the script in Jenkinsfile.
10. Run build on the Pipeline.
11. Use the cluster's external IP to launch the web app on port 5000.
12. Add new contacts, see the Contacts table being updated.


**Additional notes for some Security aspects**

1. The AWS security group has open routes for all traffic because this is a TEST project. In real project the routes would not be so open and will not allow such free access to ec2 and to the cluster.
2. Same for the variables.tf - current file doesn't include sensitive information, but either way it would've been in .gitignore file and not visible on git. This is, again, because it's a TEST project for demonstration only.
3. IAM Roles would be also more tuned and not allow all policies. This would be configured per specific needs of prod environment.
4. Git repo also would not be public, and would require to set up a Github token in Jenkins for access to clone the git.  
  
   


   
