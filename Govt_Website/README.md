
# 🏥 MediBridge AI - National Healthcare Intelligence Portal

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Appwrite](https://img.shields.io/badge/Appwrite-1.9.0-ff69b4)
![JavaScript](https://img.shields.io/badge/JavaScript-ES6-yellow)

> **Government-Authorized Healthcare Verification & Disease Intelligence System**

MediBridge AI is a comprehensive healthcare intelligence platform that streamlines medical credential verification, provides real-time disease surveillance, and enables crisis response coordination. Built for government healthcare authorities to manage doctor and student verifications, track disease outbreaks, and coordinate emergency responses across regions.

![Dashboard Preview](https://via.placeholder.com/800x400?text=MediBridge+AI+Dashboard)

## 📋 Table of Contents

- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Database Collections](#-database-collections)
- [Usage Guide](#-usage-guide)
- [Email Notifications](#-email-notifications)
- [API Endpoints](#-api-endpoints)
- [Security](#-security)
- [Troubleshooting](#-troubleshooting)
- [Deployment](#-deployment)
- [Contributing](#-contributing)
- [License](#-license)

## 🚀 Features

### Core Functionality
- **📝 Dual Verification System** - Separate verification flows for doctors and medical students
- **👑 Admin Dashboard** - Centralized management with real-time statistics
- **📧 Automated Email Notifications** - Status updates via EmailJS integration
- **🔐 Secure Authentication** - Admin login with session management

### Advanced Intelligence Features
- **📊 Disease Analytics** - Real-time trend analysis with Chart.js visualizations
- **🗺️ Regional Heatmap** - Live risk assessment across geographic zones
- **🚨 Crisis Alerts** - Priority-based emergency response system
- **🤖 AI Predictions** - Early warning system for disease outbreaks

### User Features
- **📱 Responsive Glassmorphism UI** - Modern, accessible design
- **📎 Document Upload** - Support for licenses and ID proofs
- **🔒 Password Protection** - Encrypted user credentials
- **📧 Email Confirmations** - Automatic notifications for application status

## 🛠️ Tech Stack

### Frontend
| Technology | Version | Purpose |
|------------|---------|---------|
| HTML5 | - | Structure |
| CSS3 | - | Styling with Glassmorphism |
| JavaScript | ES6 | Core functionality |
| GSAP | 3.12.2 | Animations |
| Chart.js | Latest | Data visualization |

### Backend Services
| Service | Purpose |
|---------|---------|
| **Appwrite** | Database, Backend as a Service |
| **EmailJS** | Email notifications (no SMTP config) |
| **CORS Anywhere** | Development proxy (optional) |

### Integrations
- **Font Awesome 6.4.0** - Icons
- **Google Fonts** - Inter & Outfit fonts

## 🏗️ Architecture

```
MediBridge AI/
├── Frontend (HTML/CSS/JS)
│   ├── Public Pages (Landing, Apply Forms)
│   ├── Admin Portal (Dashboard, Verification)
│   └── Intelligence Suite (Analytics, Heatmap, Alerts)
│
├── Backend Services
│   ├── Appwrite (Database & API)
│   └── EmailJS (Email Delivery)
│
└── Data Flow
    ├── User Application → doctor_requests/student_requests
    ├── Admin Approval → doctors/students collection
    ├── Email Notification → EmailJS → User Inbox
    └── Analytics Data → Appwrite → Chart.js Visualizations
```

## 💻 Installation

### Prerequisites
- Web browser (Chrome/Firefox/Edge recommended)
- Code editor (VS Code preferred)
- Appwrite account (free tier)
- EmailJS account (free tier)

### Local Development Setup

#### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/medibridge-ai.git
cd medibridge-ai
```

#### 2. Configure Appwrite

**Create Appwrite Project:**
1. Sign up at [Appwrite Cloud](https://cloud.appwrite.io)
2. Create new project → Get Project ID
3. Create Database → Get Database ID
4. Create Collections (see [Database Collections](#-database-collections))

**Set up Collections:**
```javascript
// Your Appwrite credentials (in appwrite-config.js)
const APPWRITE_ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const APPWRITE_PROJECT_ID = 'your_project_id';
const APPWRITE_DATABASE_ID = 'your_database_id';
```

#### 3. Configure EmailJS

1. Sign up at [EmailJS](https://www.emailjs.com)
2. Create Email Service (Gmail/Outlook)
3. Create "Contact Us" template with variables:
   - `{{to_name}}`
   - `{{email}}`
   - `{{subject}}`
   - `{{message}}`
   - `{{color}}`
   - `{{title}}`
4. Get your credentials:
   - Public Key (Account → API Keys)
   - Service ID (Email Services)
   - Template ID (Email Templates)

```javascript
// In appwrite-config.js
const EMAILJS_CONFIG = {
    publicKey: 'your_public_key',
    serviceId: 'your_service_id',
    templateId: 'your_template_id'
};
```

#### 4. Handle CORS for Development

**Option A: Request Demo Access**
- Visit https://cors-anywhere.herokuapp.com/corsdemo
- Click "Request temporary access"

**Option B: Self-Host CORS Proxy**
```bash
npm install -g cors-anywhere
cors-anywhere
# Update CORS_PROXY in appwrite-config.js to 'http://localhost:8080/'
```

**Option C: Configure Appwrite CORS (Production)**
- Appwrite Console → Project Settings → Security
- Add allowed origins (your domain)

#### 5. Launch Application
```bash
# Using Live Server (VS Code extension)
Right-click index.html → Open with Live Server

# OR using Python
python -m http.server 5500

# OR using Node.js
npx serve .
```

Visit: `http://localhost:5500`

## ⚙️ Configuration

### Environment Variables

Create a `config.js` file for production (optional):

```javascript
// config.js
window.APP_CONFIG = {
    APPWRITE_ENDPOINT: 'https://sgp.cloud.appwrite.io/v1',
    APPWRITE_PROJECT_ID: 'your_project_id',
    APPWRITE_DATABASE_ID: 'your_database_id',
    EMAILJS_PUBLIC_KEY: 'your_public_key',
    EMAILJS_SERVICE_ID: 'your_service_id',
    EMAILJS_TEMPLATE_ID: 'your_template_id'
};
```

### Admin Credentials (Demo)
```
Email: admin@medibridge.ai
Password: 123456
```
> **⚠️ Change these credentials in production!**

## 🗄️ Database Collections

### Required Appwrite Collections

#### 1. `doctor_requests`
| Attribute | Type | Required |
|-----------|------|----------|
| `name` | string | Yes |
| `email` | string | Yes |
| `phoneNumber` | string | Yes |
| `aadharNumber` | string | Yes |
| `licenseNumber` | string | Yes |
| `specialization` | string | Yes |
| `password` | string | Yes |
| `status` | string | Yes (pending/approved/rejected) |
| `submittedAt` | string | Yes |

#### 2. `student_requests`
| Attribute | Type | Required |
|-----------|------|----------|
| `name` | string | Yes |
| `email` | string | Yes |
| `phoneNumber` | string | Yes |
| `studentId` | string | Yes |
| `college` | string | Yes |
| `course` | string | Yes |
| `password` | string | Yes |
| `status` | string | Yes |
| `submittedAt` | string | Yes |

#### 3. `doctors`
| Attribute | Type | Required |
|-----------|------|----------|
| `doctorId` | string | Yes |
| `name` | string | Yes |
| `email` | string | Yes |
| `specialization` | string | Yes |
| `password` | string | Yes |
| `isActive` | boolean | Yes |
| `approvedAt` | string | Yes |

#### 4. `students`
| Attribute | Type | Required |
|-----------|------|----------|
| `studentId` | string | Yes |
| `name` | string | Yes |
| `email` | string | Yes |
| `college` | string | Yes |
| `course` | string | Yes |
| `password` | string | Yes |
| `isActive` | boolean | Yes |
| `approvedAt` | string | Yes |

## 📖 Usage Guide

### For Applicants

#### Doctor Registration
1. Visit → Click "Verify as Doctor"
2. Fill form including:
   - Personal details (name, email, phone)
   - Professional details (Aadhar, license, specialization)
   - Create password (minimum 6 characters)
   - Upload medical license
3. Submit → Receive confirmation email
4. Wait for admin approval

#### Student Registration
1. Visit → Click "Verify as Student"
2. Fill form including:
   - Personal details
   - Educational details (college, course, year)
   - Create password
   - Upload college ID
3. Submit → Receive confirmation email

### For Administrators

#### Access Admin Panel
1. Click "Admin" on homepage
2. Login with credentials
3. Access 6 modules:

#### 1. Dashboard
- View real-time statistics
- Monitor pending applications
- Track verified users

#### 2. Doctor Verification
- Review doctor applications
- Approve/Reject with reason
- Automatic email notifications

#### 3. Student Verification
- Review student applications
- Grant/Deny access
- Automatic email notifications

#### 4. Intelligence Analytics
- View disease trend charts
- Analyze regional distribution
- Demographic impact metrics

#### 5. Regional Heatmap
- Visualize risk zones
- Monitor disease clusters
- Track outbreak patterns

#### 6. Crisis Alerts
- View active emergencies
- Deploy response teams
- Issue public advisories

## 📧 Email Notifications

### Automated Emails

| Trigger | Recipient | Email Type |
|---------|-----------|------------|
| Application submitted | Applicant | Confirmation |
| Application approved | Applicant | Approval notice |
| Application rejected | Applicant | Rejection with reason |

### Email Templates (EmailJS)

**Contact Us Template Variables:**
```html
To: {{email}}
Subject: {{subject}}
Content:
  Dear {{to_name}},
  {{message}}
  
  Best regards,
  MediBridge AI Team
```

### Testing Email
```javascript
// Browser console
appwriteService.sendEmailNotification(
    'test@example.com',
    'Test Subject',
    'Test message',
    'status'
);
```

## 🔌 API Endpoints

### Appwrite Service Methods

```javascript
// Create document
appwriteService.createDocument(collectionId, data)

// Get documents (admin only)
appwriteService.getDocuments(collectionId)

// Update document (admin only)
appwriteService.updateDocument(collectionId, documentId, data)

// Send email
appwriteService.sendEmailNotification(to, subject, message, type)

// Send status email
appwriteService.sendApplicationStatusEmail(email, name, status, remarks)
```

## 🔒 Security

### Implemented Measures
- ✅ Admin session management (localStorage)
- ✅ Password encryption (Base64 - upgrade to bcrypt for production)
- ✅ CORS protection
- ✅ Input validation
- ✅ XSS prevention (escapeHtml utility)

### Recommended Production Upgrades
- 🔐 Implement proper password hashing (bcrypt)
- 🔐 Use HTTPS everywhere
- 🔐 Implement rate limiting
- 🔐 Add CSRF tokens
- 🔐 Use environment variables for secrets
- 🔐 Implement 2FA for admin accounts

## 🐛 Troubleshooting

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **CORS errors (403/429)** | Visit cors-anywhere demo page OR configure Appwrite CORS |
| **Email not sending** | Verify EmailJS credentials in appwrite-config.js |
| **Database errors** | Check collection attributes match code expectations |
| **Login fails** | Clear localStorage and re-login |
| **Password issues** | Ensure minimum 6 characters during registration |
| **Charts not loading** | Check Chart.js CDN is accessible |

### Debug Mode
```javascript
// Enable verbose logging
localStorage.setItem('debug', 'true');

// Check console for:
// - EmailJS initialization
// - API requests/responses
// - Database operations
```

## 🚀 Deployment

### Deploy to Netlify (Recommended)

1. Push code to GitHub repository
2. Sign up at [Netlify](https://netlify.com)
3. Click "New site from Git"
4. Connect GitHub repository
5. Configure build settings:
   - Build command: (none for static site)
   - Publish directory: `./`
6. Deploy!

### Deploy to Vercel

```bash
npm install -g vercel
vercel
```

### Deploy to GitHub Pages

1. Repository → Settings → Pages
2. Branch: `main` / `/ (root)`
3. Save → Access via `https://username.github.io/repo`

### Post-Deployment Checklist
- [ ] Update Appwrite allowed origins with production URL
- [ ] Update CORS proxy configuration (remove if using Appwrite directly)
- [ ] Test email notifications
- [ ] Verify all API endpoints work
- [ ] Test on mobile devices

## 📁 Project Structure

```
medibridge-ai/
│
├── index.html                 # Landing page
├── style.css                  # Global styles
├── script.js                  # Main application logic
├── appwrite-config.js         # Appwrite & EmailJS config
│
├── Admin Pages/
│   ├── admin-login.html       # Admin authentication
│   ├── dashboard.html         # Main dashboard
│   ├── doctor-verification.html
│   ├── student-verification.html
│   ├── analytics.html         # Disease intelligence
│   ├── heatmap.html           # Regional risk mapping
│   └── alerts.html            # Crisis response
│
├── Public Forms/
│   ├── doctor-apply.html      # Doctor registration
│   └── student-apply.html     # Student registration
│
└── Assets/
    ├── screenshots/           # Documentation images
    └── docs/                  # Additional documentation
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Development Guidelines
- Follow existing code style
- Test thoroughly before submitting PR
- Update documentation for new features
- Ensure responsive design on all devices

## 📄 License

This project is licensed under the MIT License - see below:

```
MIT License

Copyright (c) 2024 MediBridge AI

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions...

[Full MIT license text]
```

## 🙏 Acknowledgments

- **Appwrite** - Backend infrastructure
- **EmailJS** - Email delivery service
- **Font Awesome** - Icon library
- **Google Fonts** - Typography
- **GSAP** - Smooth animations
- **Chart.js** - Data visualization

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/yourusername/medibridge-ai/issues)
- **Email**: support@medibridge.gov.in
- **Admin Portal**: [Access Here](https://yourdomain.com/admin-login.html)

---

## ⭐ Show Your Support

If this project helped you, please give it a ⭐ on GitHub!

---

**Built with ❤️ for the Ministry of Health & Family Welfare, Government of India**

*Version 1.0.0 | Last Updated: 2024*
```

---

## 📝 What This README Includes

| Section | Purpose |
|---------|---------|
| **Features** | Overview of all system capabilities |
| **Tech Stack** | Complete technology listing |
| **Installation** | Step-by-step setup guide |
| **Database Collections** | Exact schema for Appwrite |
| **Usage Guide** | How to use for applicants & admins |
| **Email Notifications** | EmailJS configuration |
| **Security** | Current & recommended measures |
| **Troubleshooting** | Common issues & solutions |
| **Deployment** | Hosting instructions |
| **Project Structure** | File organization |

## 🎨 Optional: Add Screenshots

For a more visual README, add screenshots:

```markdown
## Screenshots

### Landing Page
![Landing Page](screenshots/landing.png)

### Admin Dashboard
![Dashboard](screenshots/dashboard.png)

### Verification Panel
![Verification](screenshots/verification.png)

### Disease Analytics
![Analytics](screenshots/analytics.png)

### Crisis Alerts
![Alerts](screenshots/alerts.png)
```
