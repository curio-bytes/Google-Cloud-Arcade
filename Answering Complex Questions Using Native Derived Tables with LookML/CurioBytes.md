
<h2 align="center">
Answering Complex Questions Using Native Derived Tables with LookML | GSP935
</h2>

<div align="center">
  <a href="https://www.cloudskillsboost.google/games/6215/labs/39409" target="_blank" rel="noopener noreferrer">
    <img src="https://img.shields.io/badge/Open_Lab-Cloud_Skills_Boost-4285F4?style=for-the-badge&logo=google&logoColor=white&labelColor=34A853" alt="Open Lab Badge">
  </a>
</div>

---

## ❗ Important Notice ❗

<blockquote style="background-color: #fffbea; border-left: 6px solid #f7c948; padding: 1em; font-size: 15px; line-height: 1.5;">
  <strong>For Learning Use Only:</strong> This walkthrough is intended <em>strictly for educational use</em> to assist with understanding Google Cloud features and to level up your technical skills.
  <br><br>
  <strong>Respect the Rules:</strong> Please make sure you're adhering to Qwiklabs’ terms and YouTube’s community guidelines. The goal is to support your growth—not to bypass platform rules.
</blockquote>

---
### 👉 Please follow video instructions to get complete points : [Video Link](https://youtu.be/V3Q8Q31h2M8)

<div style="padding: 15px; margin: 10px 0;">
<p><strong>💻 1. Create new view named `brand_order_facts` </strong></p>
Copy and paste the code in 'brand_order_facts.view' file.

  
```bash

view: brand_order_facts {
  derived_table: {
    explore_source: order_items {
      column: product_brand { field: inventory_items.product_brand }
      column: total_revenue {}
      derived_column: brand_rank {
        sql: row_number() over (order by total_revenue desc) ;;
      }
      filters: [order_items.created_date: "365 days"]
      
      bind_filters: {
        from_field: order_items.created_date
        to_field: order_items.created_date
      }
    }
  }
  
  dimension: brand_rank {
    hidden: yes
    type: number
  }
  dimension: product_brand {
    description: ""
  }
  
  dimension: brand_rank_concat {
    label: "Brand Name"
    type: string
    sql: ${brand_rank} || ') ' || ${product_brand} ;;
  }
  
  dimension: brand_rank_top_5 {
    hidden: yes
    type: yesno
    sql: ${brand_rank} <= 5 ;;
  }
  
  dimension: brand_rank_grouped {
    label: "Brand Name Grouped"
    type: string
    sql: case when ${brand_rank_top_5} then ${brand_rank_concat} else '6) Other' end ;;
  }
  
  dimension: total_revenue {

    description: ""
    value_format: "$#,##0.00"
    type: number
  }
}

```
</div>

<div style="padding: 15px; margin: 10px 0;">
<p><strong>💻 2. Code for Updating the `training_ecommerce` model.</strong></p>
Modify the 'training_ecommerce.model' file with following code.

  
```bash

connection: "bigquery_public_data_looker"

include: "/views/*.view"
include: "/z_tests/*.lkml"
include: "/**/*.dashboard"

datagroup: training_ecommerce_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: training_ecommerce_default_datagroup

label: "E-Commerce Training"

explore: order_items {
  join: users {
    type: left_outer
    sql_on: ${order_items.user_id} = ${users.id} ;;
    relationship: many_to_one
  }

  join: brand_order_facts {
    type: left_outer
    sql_on: ${inventory_items.product_brand} = ${brand_order_facts.product_brand} ;;
    relationship: many_to_one
  }

  join: inventory_items {
    type: left_outer
    sql_on: ${order_items.inventory_item_id} = ${inventory_items.id} ;;
    relationship: many_to_one
  }

  join: products {
    type: left_outer
    sql_on: ${inventory_items.product_id} = ${products.id} ;;
    relationship: many_to_one
  }

  join: distribution_centers {
    type: left_outer
    sql_on: ${products.distribution_center_id} = ${distribution_centers.id} ;;
    relationship: many_to_one
  }
}

explore: events {
  join: event_session_facts {
    type: left_outer
    sql_on: ${events.session_id} = ${event_session_facts.session_id} ;;
    relationship: many_to_one
  }
  join: event_session_funnel {
    type: left_outer
    sql_on: ${events.session_id} = ${event_session_funnel.session_id} ;;
    relationship: many_to_one
  }
  join: users {
    type: left_outer
    sql_on: ${events.user_id} = ${users.id} ;;
    relationship: many_to_one
  }
}


# Place in `training_ecommerce` model
explore: +order_items {
  query: Model1 {
    dimensions: [brand_order_facts.brand_rank_grouped]
    measures: [total_revenue]
  }
}



# Place in `training_ecommerce` model
explore: +order_items {
    query: Model2 {
      dimensions: [inventory_items.product_brand]
      measures: [total_revenue]
    }
}



# Place in `training_ecommerce` model
explore: +order_items {
    query: Model3 {
      dimensions: [brand_order_facts.brand_rank_grouped, created_date, users.age, users.country]
      measures: [total_revenue]
      filters: [
        order_items.created_date: "365 days",
        users.age: ">21",
        users.country: "USA"
      ]
    }
}

```
</div>

---
## 🎉 Congratulations! You Completed the Lab Successfully! 🏆

### Thanks for watching ! 💮 [Subscribe Youtube Channel ▶️](https://youtube.com/@curio_bytes_15?si=rJfZC1bLswC79o3V)
---
