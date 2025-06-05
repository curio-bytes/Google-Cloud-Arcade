
<h2 align="center">
Getting Started with Liquid to Customize the Looker User Experience | GSP933
</h2>

<div align="center">
  <a href="https://www.cloudskillsboost.google/games/6217/labs/39427" target="_blank" rel="noopener noreferrer">
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
### 👉 Please follow video instructions to get complete points : [Video Link](https://youtu.be/NUi8zmTgKlg)

<div style="padding: 15px; margin: 10px 0;">
<p><strong>💻 1. Code for Updating the "users" view.</strong></p>
Copy and paste the code in `users.view` file.

  
```bash
view: user_facts {
  derived_table: {
    sql: SELECT
           order_items.user_id AS user_id
          ,COUNT(distinct order_items.order_id) AS lifetime_order_count
          ,SUM(order_items.sale_price) AS lifetime_revenue
          ,MIN(order_items.created_at) AS first_order_date
          ,MAX(order_items.created_at) AS latest_order_date
          FROM cloud-training-demos.looker_ecomm.order_items
          WHERE {% condition select_date %} order_items.created_at {% endcondition %}
          GROUP BY user_id;;
  }
  
  filter: select_date {
    type: date
    suggest_explore: order_items
    suggest_dimension: order_items.created_date
  }

  measure: count {
    hidden: yes
    type: count
    drill_fields: [detail*]
  }

  dimension: user_id {
    primary_key: yes
    type: number
    sql: ${TABLE}.user_id ;;
  }

  dimension: lifetime_order_count {
    type: number
    sql: ${TABLE}.lifetime_order_count ;;
  }

  dimension: lifetime_revenue {
    type: number
    sql: ${TABLE}.lifetime_revenue ;;
  }

  measure: average_lifetime_revenue {
    type: average
    sql: ${TABLE}.lifetime_revenue ;;
  }


  measure: average_lifetime_order_count {
    type: average
    sql: ${TABLE}.lifetime_order_count ;;
  }

  dimension_group: first_order_date {
    type: time
    sql: ${TABLE}.first_order_date ;;
  }

  dimension_group: latest_order_date {
    type: time
    sql: ${TABLE}.latest_order_date ;;
  }

  set: detail {
    fields: [user_id, lifetime_order_count, lifetime_revenue, first_order_date_time, latest_order_date_time]
  }
}
```
</div>

<div style="padding: 15px; margin: 10px 0;">
<p><strong>💻 2. Code for Updating the "order_items" view.</strong></p>
Modify the `order_items` model file with following code.

  
```bash
view: order_items {
    sql_table_name: `cloud-training-demos.looker_ecomm.order_items`
      ;;
    drill_fields: [order_item_id]
  
    dimension: order_item_id {
      primary_key: yes
      type: number
      sql: ${TABLE}.id ;;
    }
  
    dimension_group: created {
      type: time
      timeframes: [
        raw,
        time,
        date,
        week,
        month,
        quarter,
        year
      ]
      sql: ${TABLE}.created_at ;;
    }
  
    dimension_group: delivered {
      type: time
      timeframes: [
        raw,
        date,
        week,
        month,
        quarter,
        year
      ]
      convert_tz: no
      datatype: date
      sql: ${TABLE}.delivered_at ;;
    }
  
    dimension: inventory_item_id {
      type: number
      # hidden: yes
      sql: ${TABLE}.inventory_item_id ;;
    }
  
    dimension: order_id {
      type: number
      sql: ${TABLE}.order_id ;;
    }
  
    dimension_group: returned {
      type: time
      timeframes: [
        raw,
        time,
        date,
        week,
        month,
        quarter,
        year
      ]
      sql: ${TABLE}.returned_at ;;
    }
  
    dimension: sale_price {
      type: number
      sql: ${TABLE}.sale_price ;;
    }
  
    dimension_group: shipped {
      type: time
      timeframes: [
        raw,
        date,
        week,
        month,
        quarter,
        year
      ]
      convert_tz: no
      datatype: date
      sql: ${TABLE}.shipped_at ;;
    }
  
    dimension: status {
      type: string
      sql: ${TABLE}.status ;;
    }
  
    dimension: user_id {
      type: number
      # hidden: yes
      sql: ${TABLE}.user_id ;;
    }
  
  
    measure: average_sale_price {
      type: average
      sql: ${sale_price} ;;
      drill_fields: [detail*]
      value_format_name: usd_0
    }
  
    measure: order_item_count {
      type: count
      drill_fields: [detail*]
    }
  
    measure: order_count {
      type: count_distinct
      sql: ${order_id} ;;
    }
  
    measure: total_revenue {
      type: sum
      sql: ${sale_price} ;;
      value_format_name: usd
    }
  
    measure: total_revenue_conditional {
      type: sum
      sql: ${sale_price} ;;
      value_format_name: usd
      html: {% if value > 1300.00 %}
            <p style="color: white; background-color: ##FFC20A; margin: 0; border-radius: 5px; text-align:center">{{ rendered_value }}</p>
            {% elsif value > 1200.00 %}
            <p style="color: white; background-color: #0C7BDC; margin: 0; border-radius: 5px; text-align:center">{{ rendered_value }}</p>
            {% else %}
            <p style="color: white; background-color: #6D7170; margin: 0; border-radius: 5px; text-align:center">{{ rendered_value }}</p>
            {% endif %}
            ;;
    }
  
    measure: total_revenue_from_completed_orders {
      type: sum
      sql: ${sale_price} ;;
      filters: [status: "Complete"]
      value_format_name: usd
    }
  
    set: detail {
      fields: [
        order_item_id,
        users.last_name,
        users.id,
        users.first_name,
        inventory_items.id,
        inventory_items.product_name
      ]
    }
  }
```
</div>

---
## 🎉 Congratulations! You Completed the Lab Successfully! 🏆

### Thanks for watching ! 💮
---
