
# 🏥 MediBridge AI  
### *Bridging Healthcare, Medical Education, and Public Health Intelligence*

> **MediBridge AI** is a healthcare-focused platform designed to connect **patients**, **verified doctors**, **medical students**, and **government/public-health authorities** through a structured digital ecosystem.  
>  
> The project aims to make consultations more accessible, academic observation more organized, and public-health monitoring more intelligent — while keeping healthcare workflows modular and scalable.

---

## 📌 Problem Statement

Healthcare systems often operate in **isolated silos**:

- Patients struggle to access organized and trackable consultations
- Doctors need structured systems to manage consultation data efficiently
- Medical students have limited supervised exposure to real-world consultation workflows
- Governments and public-health systems often lack early, localized disease intelligence

As a result, there is a gap between:

- **clinical consultation**
- **medical learning**
- **public health monitoring**

### 💡 Our Solution

**MediBridge AI** proposes a unified digital ecosystem that brings these stakeholders together through:

- a **patient-doctor consultation workflow**
- a **doctor/student verification system**
- a **consultation record management system**
- a **government-style public-health intelligence dashboard**
- an architecture capable of supporting **AI-based disease trend analysis**

---

## 🎯 Vision

To build a healthcare intelligence platform that not only supports **digital consultation workflows**, but also enables:

- **supervised medical learning**
- **structured health record flow**
- **privacy-aware public-health analytics**
- **future AI-assisted healthcare intelligence**

---

# ✨ Core Modules

## 1) 👨‍⚕️ Doctor Verification Module
Doctors can apply for verification through a request system.  
Once approved by the admin/government portal, they are added to the active doctor database.

### Purpose
- ensures controlled access
- validates medical professionals
- separates approved doctors from pending applicants

---

## 2) 🎓 Student Verification Module
Medical students can apply for supervised academic access.  
Only verified students are approved for limited and structured access.

### Purpose
- supports academic observation
- enables supervised exposure to consultation records
- introduces controlled educational participation

---

## 3) 🧑‍🤝‍🧑 Patient Consultation Module
Patients can be linked to doctors for digital consultation workflows.

Each consultation can store:
- symptoms
- transcript
- diagnosis
- prescription
- OPD-style notes
- advice
- follow-up suggestions
- risk indicators
- supporting uploads

### Purpose
- centralizes consultation records
- improves accessibility
- creates a structured digital health trail

---

## 4) 📁 Upload & Medical Record Module
The system supports consultation-linked uploads such as:
- prescriptions
- reports
- medical images
- attachments

### Purpose
- keeps supporting medical data connected to consultations
- improves record organization
- allows future secure report handling

---

## 5) 🧠 AI + Public Health Intelligence Layer
The system includes a **government/public-health inspired dashboard** that demonstrates how anonymized consultation insights can be transformed into:

- regional health statistics
- disease trend tracking
- risk heatmaps
- AI-generated alerts

### Purpose
- supports health intelligence workflows
- enables outbreak-style pattern visibility
- demonstrates future AI-assisted healthcare monitoring

---

## 6) 🏛️ Government Intelligence Dashboard
A dedicated dashboard is designed in a **government portal style** to simulate how authorities could monitor:

- doctor approvals
- student approvals
- disease trend analytics
- geographical heatmaps
- AI-generated public-health alerts

### Purpose
- demonstrates administrative oversight
- visualizes system-wide intelligence
- shows the project’s scalability beyond individual consultations

---

# 🧩 Key Features

- ✅ Doctor verification workflow
- ✅ Student verification workflow
- ✅ Structured patient-doctor consultation storage
- ✅ Consultation transcript and diagnosis handling
- ✅ Prescription and OPD report support
- ✅ Upload-linked medical records
- ✅ AI alerts architecture
- ✅ Anonymized disease statistics architecture
- ✅ Government dashboard UI
- ✅ Analytics and risk heatmap simulation
- ✅ Modular backend structure using Appwrite
- ✅ Scalable database design for future expansion

---

# 🛠️ Tech Stack

## Frontend
- **HTML**
- **CSS**
- **JavaScript**
- **GSAP** (animations)
- **Chart.js** (analytics visualizations)
- **Font Awesome** (icons)

## Backend / Database
- **Appwrite**

## Planned / Extendable AI Layer
- AI-based risk detection logic
- outbreak pattern analysis
- anomaly-based public health alerts

---

# 🗄️ Appwrite Backend & Database Architecture

## Overview

**MediBridge AI** uses **Appwrite** as its backend service to manage:

- user registration and authentication-ready records
- doctor and student verification workflows
- patient records
- consultation storage
- uploads and report linking
- anonymized disease statistics
- AI-generated public-health alerts

Appwrite was selected because it provides a **clean and fast backend workflow** for document-based application development and hackathon prototyping.

---

## Why Appwrite?

We selected **Appwrite** because it offers:

- document-based database support
- fast backend integration
- cloud-hosted deployment support
- authentication compatibility
- scalable collection design
- clean separation of data modules

For this project, Appwrite acts as the **central backend hub** connecting the patient-side flow, doctor/student verification, consultation storage, and public-health dashboard.

---

# 📂 Database Collections

---

## 1) `patients`

Stores patient account details and identity-linked health access data.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `firstName` | string | 64 | Patient first name |
| `lastName` | string | 64 | Patient last name |
| `password` | string | 100 | Patient login password |
| `state` | string | 20 | State |
| `district` | string | 20 | District |
| `city` | string | 20 | City |
| `role` | string | 20 | Default role = `patient` |
| `patientId` | string | 20 | Unique patient ID |
| `WhatsApp_Number` | string | 15 | Contact number |
| `dob` | string | 10 | Date of birth |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

## 2) `doctors`

Stores approved doctors who can access consultation workflows.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `doctorId` | string | 20 | Unique doctor ID |
| `name` | string | 64 | Doctor name |
| `password` | string | 100 | Doctor password |
| `specialization` | string | 50 | Doctor specialty |
| `role` | string | 20 | Default role = `doctor` |
| `Email_ID` | email | — | Doctor email |
| `Contact_No` | string | 15 | Contact number |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

## 3) `students`

Stores approved medical students with controlled academic access.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `name` | string | 64 | Student name |
| `password` | string | 100 | Student password |
| `college` | string | 100 | College name |
| `course` | string | 50 | Course name |
| `expiresAt` | datetime | — | Access expiry |
| `role` | string | 20 | Default role = `student` |
| `studentId` | string | 20 | Unique student ID |
| `Phone_No` | string | 15 | Contact number |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

## 4) `doctor_requests`

Stores doctor verification applications before approval.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `name` | string | 64 | Applicant name |
| `email` | email | — | Applicant email |
| `phoneNumber` | string | 15 | Contact number |
| `licenseNumber` | string | 50 | Medical license |
| `specialization` | string | 50 | Specialty |
| `clinicName` | string | 50 | Clinic / hospital |
| `proofUrl` | string | 500 | Verification proof |
| `status` | string | 100 | Request status |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

## 5) `student_requests`

Stores student verification requests before approval.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `name` | string | 64 | Student name |
| `email` | email | — | Student email |
| `phoneNumber` | string | 15 | Contact number |
| `college` | string | 100 | College name |
| `course` | string | 50 | Course name |
| `year` | string | 15 | Academic year |
| `proofUrl` | string | 500 | Verification proof |
| `status` | string | 100 | Request status |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

## 6) `consultations`

Stores the main doctor-patient consultation records.

> ⚠️ This is one of the **core and already populated collections** in the current prototype.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `consultationId` | string | 30 | Unique consultation ID |
| `doctorId` | string | 20 | Linked doctor ID |
| `patientId` | string | 20 | Linked patient ID |
| `transcript` | string | 5000 | Consultation transcript |
| `diagnosis` | string | 500 | Diagnosis summary |
| `prescription` | string | 2000 | Prescription details |
| `symptoms` | string | 500 | Patient symptoms |
| `status` | string | 20 | Consultation status |
| `riskAlerts` | string | 300 | AI-detected risk indicators |
| `opdReport` | string | 5000 | Generated OPD report |
| `chiefComplaint` | string | 500 | Main complaint |
| `advice` | string | 200 | Doctor advice |
| `followUp` | string | 100 | Follow-up recommendation |
| `attachmentUrls` | string | 1000 | Related file URLs |
| `studentAccessExpiry` | string | 100 | Student access limit |
| `imageUrls` | string | 100 | Related image URLs |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

## 7) `uploads`

Stores uploaded consultation-linked records and files.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `consultationId` | string | 50 | Linked consultation |
| `uploadType` | string | 20 | Type of upload |
| `UploadedAt` | string | 50 | Upload timestamp |
| `expiresAt` | string | 50 | Expiry timestamp |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

## 8) `anonymized_stats`

Stores anonymized aggregated health statistics for analytics.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `disease` | string | 100 | Disease name |
| `district` | string | 20 | District |
| `city` | string | 20 | City |
| `state` | string | 20 | State |
| `count` | integer | 100–100000 | Number of cases |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

## 9) `ai_alerts`

Stores AI-generated public-health warnings and anomaly alerts.

| Field Name | Type | Size | Purpose |
|-----------|------|------|---------|
| `$id` | string | auto | Appwrite document ID |
| `title` | string | 50 | Alert title |
| `riskType` | string | 100 | Type of risk |
| `district` | string | 20 | Alert district |
| `severity` | string | 20 | Alert severity |
| `disease` | string | 100 | Related disease |
| `description` | string | 500 | Alert explanation |
| `$createdAt` | datetime | — | Created timestamp |
| `$updatedAt` | datetime | — | Updated timestamp |

---

# 🔄 Data Flow

## Doctor Approval Flow
`doctor_requests` → Admin Approval → `doctors`

## Student Approval Flow
`student_requests` → Admin Approval → `students`

## Consultation Flow
`patients` + `doctors` → `consultations` → `uploads`

## Public Health Intelligence Flow
`consultations` → anonymized aggregation → `anonymized_stats` → AI risk generation → `ai_alerts`

---

# 🏗️ Project Structure

```bash
MediBridgeAI/
│
├── README.md
│
├── website/
│   ├── index.html
│   ├── dashboard.html
│   ├── doctor-verification.html
│   ├── student-verification.html
│   ├── analytics.html
│   ├── heatmap.html
│   ├── alerts.html
│   ├── admin-login.html
│   ├── style.css
│   ├── script.js
│   └── appwrite-config.js
│
├── app/
│   ├── (patient / mobile-side implementation files)
│   └── ...
│
└── assets/
    ├── screenshots/
    └── media/
```

---

# 🧪 Current Prototype Status

## Implemented / Demonstrated
- Doctor verification UI
- Student verification UI
- Government dashboard UI
- Analytics dashboard UI
- Heatmap UI
- AI alerts UI
- Appwrite database architecture
- Consultation data model
- Uploads / reports architecture

## In Progress / Extendable
- secure authentication
- real-time role-based access
- AI prediction logic
- live backend-connected dashboards
- mobile-app integration refinement

---

# 🔐 Security Note

This project is currently structured as a **hackathon prototype**.

For a production-ready healthcare system, the following improvements are intended:

- secure password hashing
- Appwrite authentication integration
- role-based document permissions
- secure file storage
- encrypted sensitive medical records
- controlled API exposure
- audit logs and access monitoring

---

# 🚀 Future Scope

MediBridge AI can be extended into a full-scale healthcare intelligence ecosystem with:

- real telemedicine workflows
- AI-assisted diagnosis support
- multilingual medical accessibility
- predictive outbreak modeling
- district/state-wise disease forecasting
- medical student supervised learning portals
- government health intervention dashboards
- secure health report sharing
- cloud-hosted hospital integration

---

# 🏆 Why This Project Stands Out

MediBridge AI is not just a consultation platform.

It combines:

- **digital healthcare**
- **medical education workflows**
- **verification and trust systems**
- **privacy-aware public health intelligence**
- **future AI-readiness**

This makes it a strong concept at the intersection of:

> **HealthTech + GovTech + MedEd + AI**

---

# 👥 Team

**Team Name:** `CodeWizHub`

Built as part of a hackathon project with the aim of solving real-world healthcare workflow challenges through scalable digital infrastructure.

---

# 📌 Note

This repository reflects the **current hackathon build and architecture** of the project.  
Some modules are intentionally structured for **demonstration, extensibility, and future development readiness**.

---

# ❤️ Closing Thought

> *Healthcare is not just about treatment — it is also about access, trust, learning, and timely intelligence.*  
>  
> **MediBridge AI** is our step toward connecting all four.



