# CodeWizHub

# MediBridge AI  
### AI-Powered Rural Healthcare & Government Verification Ecosystem

MediBridge AI is a healthcare-focused digital platform designed to improve access, documentation, and administrative efficiency in underserved and rural regions.

The system combines an **AI-assisted doctor consultation workflow**, **patient-friendly medical records**, and a **government-side verification portal** to bridge the gap between healthcare delivery and healthcare administration.

This project was built with the vision of making healthcare **more accessible, understandable, and manageable** for patients, doctors, students, and government authorities.

---

## Problem Statement

In many rural and semi-urban areas:

- Patients often do not understand or preserve their consultation records properly.
- Doctors spend extra time writing reports and prescriptions manually.
- Medical records are rarely structured or accessible in local languages.
- Government verification of healthcare workers and medical students is often slow and fragmented.
- Public healthcare monitoring lacks a unified digital workflow.

MediBridge AI aims to solve these issues through a single integrated system.

---

## Solution Overview

MediBridge AI provides a connected ecosystem with two major components:

### 1. Healthcare Application
A doctor-patient consultation system that:
- Records consultations
- Converts speech into structured medical documentation
- Generates OPD reports and prescriptions
- Stores records digitally
- Allows patients to access reports later
- Supports local-language accessibility for better understanding

### 2. Government Web Portal
A centralized administrative dashboard that:
- Supports doctor verification workflows
- Supports student verification workflows
- Provides admin-side monitoring and record management
- Serves as a government-facing digital health oversight platform

Together, these modules create a more connected, transparent, and scalable healthcare support system.

---

## Key Objectives

- Improve doctor workflow efficiency
- Reduce manual documentation burden
- Make consultation summaries easier for patients to understand
- Digitize healthcare records in a structured way
- Support multilingual accessibility
- Enable government-side verification and oversight
- Build a scalable healthcare-tech ecosystem for broader deployment

---

## Core Modules

### Doctor Side
- Patient search and consultation initiation
- Audio-based consultation capture
- AI-assisted transcript processing
- Structured OPD report generation
- Prescription generation
- Consultation history support

### Patient Side
- View consultation records
- Access OPD reports and prescriptions
- Language-based report viewing
- Simplified health record access

### Government Website
- Welcome/landing interface
- Doctor verification panel
- Student verification panel
- Admin login and access-controlled dashboard
- Monitoring and verification management

---

## Tech Stack

### Frontend
- **Flutter** (Mobile Application)
- **HTML**
- **CSS**
- **JavaScript**

### Backend / Services
- **Appwrite** (Database, Auth, Backend Services)
- **Firebase** (used in project workflow where applicable)

### AI / APIs
- **Groq Whisper API** – Speech-to-text transcription
- **Google Gemini API** – Structured medical report generation and translation assistance

### Other Tools
- **Git & GitHub** – Version control and collaboration
- **PDF generation libraries** – Report / prescription exports

---

## Project Structure

```bash
MediBridge-AI/
│
├── app/                     # Flutter mobile application
│   ├── screens/
│   ├── services/
│   ├── widgets/
│   └── ...
│
├── website/                 # Government/admin verification website
│   ├── index.html
│   ├── dashboard.html
│   ├── doctor-verification.html
│   ├── student-verification.html
│   ├── analytics.html
│   ├── alerts.html
│   ├── heatmap.html
│   ├── style.css
│   └── script.js
│
├── docs/                    # Documentation / assets / screenshots (optional)
│
└── README.md
