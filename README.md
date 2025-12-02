# User-Funnel-Drop-Off-Diagnosis
# 📊 User Funnel Drop-Off Diagnosis (SQL + Python)

A complete end-to-end funnel analysis project built using **PostgreSQL + Python (pandas/matplotlib)** over **50,000+ real-looking user events**.  
This project demonstrates product analytics, user behavior modelling, and funnel optimization — all skills expected in founders' office, business analyst, growth, and product roles.

---

## 🔍 Project Overview

The goal of this project is to diagnose where users drop off in the journey from:

Install → Signup → View Product → Add to Cart → Checkout → Purchase


The dataset contains:

- **12,000 users**
- **50,000+ product events**
- **5 acquisition campaigns (Google, Facebook, Instagram, Organic, Referral)**
- **3 device types (Android, iOS, Web)**

This project replicates how a real startup would analyze funnel leakage and acquisition quality.

---

## 🧠 Key Insights

### ✔ Overall Funnel
| Step | Users | Conversion | Drop-off |
|------|--------|------------|----------|
| Install | 12,000 | 100% | - |
| Signup | 12,000 | 100% | 0% |
| View Product | 10,777 | 89.8% | **10.2% lost** |
| Add to Cart | 8,434 | 78.2% | **21.8% lost** |
| Checkout | 4,222 | 50.0% | **50% lost** |
| Purchase | 1,871 | 44.3% | **55.7% lost** |

**Largest leakages:**  
- View → Cart  
- Cart → Checkout  
- Checkout → Purchase  

---

## 🗂 Tech Stack

### **SQL**
- CTEs  
- Window functions  
- Funnel modelling  
- Cohort analysis  
- Segmentation by campaign & device  

### **Python**
- Pandas preprocessing  
- Funnel metrics  
- Visualization (matplotlib)  
- Export for Power BI dashboards  

### **Visualization**
- Python charts  
- Power BI (funnel, matrix, cohort heatmap)  

---

## 🛠 SQL Artifacts

**1. User-level funnel table**  
**2. Funnel + conversion rate calculation**  
**3. Campaign-level funnel**  
**4. Device-level funnel**  
**5. Weekly cohort funnel**  
**6. Campaign × Device matrix**

---

## 📈 Python Visualizations

- Step-wise funnel bar chart  
- Drop-off line chart  
- Campaign funnel comparison  
- Exported clean user_funnel.csv for BI tools  


---







