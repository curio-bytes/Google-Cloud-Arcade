<h2 align="center">
VPC Flow Logs - Analyzing Network Traffic | GSP212
</h2>

<div align="center">
  <a href="https://www.cloudskillsboost.google/games/6213/labs/39389" target="_blank" rel="noopener noreferrer">
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

<div style="padding: 15px; margin: 10px 0;">
<p><strong>☁️Run the code in Cloud Shell:</strong></p>

```
export ZONE=
```

```bash
curl -LO https://raw.githubusercontent.com/curio-bytes/Google-Cloud-Arcade/main/VPC%20Flow%20Logs%20-%20Analyzing%20Network%20Traffic/curio-bytes.sh
sudo chmod +x curio-bytes.sh
./curio-bytes.sh
```
</div>

<div style="padding: 15px; margin: 10px 0;">
<p><strong>-> For the Sink name, enter "bq_vpcflows"</strong></p>

```
export MY_SERVER=$(gcloud compute instances describe web-server --zone "$ZONE" --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

for ((i=1;i<=50;i++)); do curl $MY_SERVER; done
```

</div>

<div style="padding: 15px; margin: 10px 0;">
<p><strong>-> Add the following to the BigQuery Editor and REPLACE_YOUR_TABLE_ID with TABLE_ID while retaining the accents (`) on both sides:
</strong></p>

#### > Query 1 :- 

```
#standardSQL
SELECT
jsonPayload.src_vpc.vpc_name,
SUM(CAST(jsonPayload.bytes_sent AS INT64)) AS bytes,
jsonPayload.src_vpc.subnetwork_name,
jsonPayload.connection.src_ip,
jsonPayload.connection.src_port,
jsonPayload.connection.dest_ip,
jsonPayload.connection.dest_port,
jsonPayload.connection.protocol
FROM
`REPLACE_YOUR_TABLE_ID`
GROUP BY
jsonPayload.src_vpc.vpc_name,
jsonPayload.src_vpc.subnetwork_name,
jsonPayload.connection.src_ip,
jsonPayload.connection.src_port,
jsonPayload.connection.dest_ip,
jsonPayload.connection.dest_port,
jsonPayload.connection.protocol
ORDER BY
bytes DESC
LIMIT
15

```
#### > Query 2 :- 

```
#standardSQL
SELECT
jsonPayload.connection.src_ip,
jsonPayload.connection.dest_ip,
SUM(CAST(jsonPayload.bytes_sent AS INT64)) AS bytes,
jsonPayload.connection.dest_port,
jsonPayload.connection.protocol
FROM
`REPLACE_YOUR_TABLE_ID`
WHERE jsonPayload.reporter = 'DEST'
GROUP BY
jsonPayload.connection.src_ip,
jsonPayload.connection.dest_ip,
jsonPayload.connection.dest_port,
jsonPayload.connection.protocol
ORDER BY
bytes DESC
LIMIT
15
```

</div>



---
## 🎉 Congratulations! You Completed the Lab Successfully! 🏆

### Thanks for watching ! 💮 [Subscribe Youtube Channel ▶️](https://youtube.com/@curio_bytes_15?si=rJfZC1bLswC79o3V)
---
