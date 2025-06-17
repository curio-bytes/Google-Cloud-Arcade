<h2 align="center">
Using Role-based Access Control in Kubernetes Engine | GSP493
</h2>

<div align="center">
  <a href="https://www.cloudskillsboost.google/games/6215/labs/39408" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---

## ❗Important Notice❗

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>For Learning Use Only:</strong> This walkthrough is intended <em>strictly for educational use</em> to assist with understanding Google Cloud features and to level up your technical skills.
  <br><br>
  <strong>Respect the Rules:</strong> Please make sure you're adhering to Qwiklabs’ terms and YouTube’s community guidelines. The goal is to support your growth—not to bypass platform rules.
</blockquote>

---

### Set your region and zone

* Open Google Cloud Console.
* On the top-right corner, click on the Cloud Shell icon to open Cloud Shell.

```
export Region=
```

```
export Zone=
```

* In the Cloud Shell terminal, run the following command to set your region: 

```
gcloud config set compute/zone us-east4-b
```
### Task 1. Clone Demo

```
gsutil cp gs://spls/gsp493/gke-rbac-demo.tar .
```
```
 tar -xvf gke-rbac-demo.tar
```

* Change into the extracted directory by:
```
cd gke-rbac-demo  
```
```
make create
```
### Task 2: Scenario 1: Assigning permissions by user persona 

* Open Cloud Shell.
* Run the command:
```
gcloud iam service-accounts list
```
``` 
gcloud compute instances list
```

* Connect to SSH :
```
gcloud compute ssh gke-tutorial-admin
```
``` 
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
```

* Add the plugin environment variable
```
echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc
source ~/.bashrc
```
* Update the cluster credentials
```
gcloud container clusters get-credentials rbac-demo-cluster --zone ZONE
```
* Apply the RBAC configuration
```
kubectl apply -f ./manifests/rbac.yaml
```

### SSH into the owner instance
* Open a new Cloud Shell terminal.
* SSH into the owner instance by running:
```
gcloud compute ssh gke-tutorial-owner
```
* Install the gke-gcloud-auth-plugin
```
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
 echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc
 source ~/.bashrc
```
* Update the cluster credentials
```
gcloud container clusters get-credentials rbac-demo-cluster --zone ZONE
```
### Deploy resources in each namespace

* In Cloud Shell on the owner instance, deploy the server in the dev namespace :
```
kubectl create -n dev -f ./manifests/hello-server.yaml
```
* Deploy the server in the prod namespace:
```
kubectl create -n prod -f ./manifests/hello-server.yaml
```
* Deploy the server in the test namespace:
```
kubectl create -n test -f ./manifests/hello-server.yaml
```
* List all hello-server pods in all namespaces:
```
kubectl get pods -l app=hello-server --all-namespaces
```

### SSH into the auditor instance
* Open a new Cloud Shell terminal.
* SSH into the auditor instance:
```
gcloud compute ssh gke-tutorial-auditor
```
* Install the gke-gcloud-auth-plugin:
```
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
 echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc
 source ~/.bashrc
```
* Update the cluster credentials
```
gcloud container clusters get-credentials rbac-demo-cluster --zone ZONE
```

### Task 3: Scenario 2 - Assigning API permissions to a cluster application

### Deploying the Sample Application

* Open the first window "admin instance" of Cloud Shell in your GCP console.
* Deploy the pod-labeler application by executing the command:
```
kubectl apply -f manifests/pod-labeler.yaml
```

### Fixing the Service Account Name

* Inspect the pod's configuration to see the service account being used:
```
kubectl get pod -oyaml -l app=pod-labeler
```
* Apply the fix by executing:
```
kubectl apply -f manifests/pod-labeler-fix-1.yaml
```

### Identifying the application's role and permissions

* Inspect the RoleBinding definition:
```
kubectl get rolebinding pod-labeler -oyaml
```
* Inspect the Role definition to see the permissions granted:
```
kubectl get role pod-labeler -oyaml
```
* Apply the new role permissions by executing:
```
kubectl apply -f manifests/pod-labeler-fix-2.yaml
```

### Now Check your Progress ✔


---
## 🎉 Congratulations! You Completed the Lab Successfully! 🏆  

### Thanks for watching ! 💮 [Subscribe Youtube Channel ▶️](https://youtube.com/@curio_bytes_15?si=rJfZC1bLswC79o3V)
---
