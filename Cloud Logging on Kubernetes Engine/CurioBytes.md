
<h2 align="center">
Cloud Logging on Kubernetes Engine | GSP483
</h2>

<div align="center">
  <a href="https://www.cloudskillsboost.google/games/6276/labs/39705" target="_blank" rel="noopener noreferrer">
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

#### Please follow video's instruction carefully to get all tasks completed 👉 : [Video Link](https://youtu.be/-i6GREoOpS8)

### ☁️Run the code in Cloud Shell:

```bash
curl -LO https://raw.githubusercontent.com/curio-bytes/Google-Cloud-Arcade/main/Cloud%20Logging%20on%20Kubernetes%20Engine/curio-bytes.sh
sudo chmod +x curio-bytes.sh
./curio-bytes.sh
```
```
cd gke-logging-sinks-demo
```


### Update the provider.tf file using following code :-
```
provider "google" {
  project = var.project
  version = "~> 2.19.0"
}
```
Save and close the file.

### Update the main.tf file by changing resource.type value at line no 110 and 119:- 
```
k8s_container
```
Save and close the file.

### Now run the following command to build out the executable environment using the make command:

```
make create
``` 

### Now, follow video's instructions carefully !!

---
## 🎉 Congratulations! You Completed the Lab Successfully! 🏆

### Thanks for watching ! 💮 [Subscribe Youtube Channel ▶️](https://youtube.com/@curio_bytes_15?si=rJfZC1bLswC79o3V)
---
