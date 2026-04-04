// MediBridge AI - Main Application Script

document.addEventListener('DOMContentLoaded', () => {
    // Check if we're on an admin page
    const adminPages = ['dashboard.html', 'doctor-verification.html', 'student-verification.html', 'analytics.html', 'heatmap.html', 'alerts.html'];
    const currentPage = window.location.pathname.split('/').pop();
    const isAdminPage = adminPages.includes(currentPage);
    
    // Auth check for admin pages
    if (isAdminPage) {
        const isLoggedIn = localStorage.getItem('adminLoggedIn');
        if (!isLoggedIn) {
            window.location.href = 'admin-login.html';
            return;
        }
    }
    
    // Initialize page-specific functions
    initPageFunctions();
});

// Page-specific initializers
function initPageFunctions() {
    const page = window.location.pathname.split('/').pop();
    
    switch(page) {
        case 'dashboard.html':
            loadDashboardStats();
            break;
        case 'doctor-verification.html':
            loadDoctorRequests();
            break;
        case 'student-verification.html':
            loadStudentRequests();
            break;
        case 'analytics.html':
            loadAnalyticsData();
            break;
        case 'heatmap.html':
            loadHeatmapData();
            break;
        case 'alerts.html':
            loadAlertsData();
            break;
        case 'doctor-apply.html':
            initDoctorApplyForm();
            break;
        case 'student-apply.html':
            initStudentApplyForm();
            break;
        case 'admin-login.html':
            initAdminLogin();
            break;
        case 'index.html':
            initLandingPage();
            break;
    }
}

// Landing Page Functions
function initLandingPage() {
    // Check if admin is already logged in (optional)
    const adminLoggedIn = localStorage.getItem('adminLoggedIn');
    if (adminLoggedIn) {
        // Show admin indicator
        const adminBtn = document.querySelector('.admin-login-btn');
        if (adminBtn) {
            adminBtn.innerHTML = '<i class="fa-solid fa-user-shield"></i> Dashboard';
            adminBtn.href = 'dashboard.html';
        }
    }
}

// Admin Login Functions
function initAdminLogin() {
    const form = document.getElementById('admin-login-form');
    if (form) {
        form.addEventListener('submit', handleAdminLogin);
    }
}

function handleAdminLogin(e) {
    e.preventDefault();
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const errorMsg = document.getElementById('error-msg');
    const btn = e.target.querySelector('button');
    
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Authenticating...';
    btn.disabled = true;
    
    setTimeout(() => {
        if (email === 'admin@medibridge.ai' && password === '123456') {
            localStorage.setItem('adminLoggedIn', 'true');
            localStorage.setItem('adminEmail', email);
            window.location.href = 'dashboard.html';
        } else {
            errorMsg.style.display = 'block';
            errorMsg.innerText = 'Access Denied: Invalid Credentials';
            btn.innerHTML = 'Secure Access';
            btn.disabled = false;
        }
    }, 1000);
}

// Admin Logout
function logout() {
    localStorage.removeItem('adminLoggedIn');
    localStorage.removeItem('adminEmail');
    window.location.href = 'index.html';
}

// Dashboard Stats Functions
async function loadDashboardStats() {
    // Show loading states
    showLoadingStates();
    
    try {
        // Fetch counts from different collections
        // For hackathon demo, we'll use simulated data
        // In production, replace with actual Appwrite calls
        
        // Simulate API calls
        const stats = await simulateDashboardStats();
        
        // Update UI
        updateStatCards(stats);
        updateRecentActivity(stats.recentActivity);
        
    } catch (error) {
        console.error('Error loading dashboard stats:', error);
        showToast('Failed to load dashboard data', 'error');
    }
}

function simulateDashboardStats() {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve({
                doctorRequests: 1240,
                doctorPending: 45,
                studentRequests: 3150,
                studentPending: 28,
                approvedDoctors: 1195,
                approvedStudents: 3122,
                totalConsultations: 8750,
                recentActivity: [
                    { type: 'doctor', name: 'Dr. Sarah Jenkins', action: 'approved', time: '2 minutes ago' },
                    { type: 'student', name: 'James Anderson', action: 'pending', time: '15 minutes ago' },
                    { type: 'doctor', name: 'Dr. Michael Chen', action: 'rejected', time: '1 hour ago' },
                    { type: 'student', name: 'Priya Patel', action: 'approved', time: '3 hours ago' }
                ]
            });
        }, 500);
    });
}

function updateStatCards(stats) {
    const statValues = document.querySelectorAll('.value');
    if (statValues.length >= 4) {
        statValues[0].innerText = stats.doctorRequests.toLocaleString();
        statValues[1].innerText = stats.studentRequests.toLocaleString();
        statValues[2].innerText = stats.totalConsultations.toLocaleString();
        statValues[3].innerText = stats.doctorPending + stats.studentPending;
    }
}

function showLoadingStates() {
    const values = document.querySelectorAll('.value');
    values.forEach(val => {
        if (val.innerText === '0' || val.innerText === '1,240') {
            val.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
        }
    });
}

// Doctor Verification Functions
async function loadDoctorRequests() {
    const tbody = document.querySelector('#doctor-table tbody');
    if (!tbody) return;
    
    tbody.innerHTML = '<tr><td colspan="5" style="text-align: center;"><i class="fa-solid fa-spinner fa-spin"></i> Loading verification requests...</td></tr>';
    
    try {
        // Simulate fetching from doctor_requests
        const requests = await simulateDoctorRequests();
        
        if (requests.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" style="text-align: center;">No pending verification requests</td></tr>';
            return;
        }
        
        tbody.innerHTML = requests.map(req => `
            <tr data-id="${req.id}" data-email="${req.email}" data-name="${req.name}" data-specialization="${req.specialization}" data-license="${req.licenseNumber}" data-phone="${req.phone}">
                <td>
                    <div class="user-cell">
                        <div class="user-avatar" style="background: linear-gradient(135deg, #8b5cf6, #06b6d4);">${getInitials(req.name)}</div>
                        <div>
                            <p style="font-weight: 600;">${escapeHtml(req.name)}</p>
                            <p style="font-size: 0.75rem; color: var(--text-muted);">${escapeHtml(req.email)}</p>
                        </div>
                    </div>
                </td>
                <td><code style="background: rgba(255,255,255,0.05); padding: 4px 8px; border-radius: 5px;">${escapeHtml(req.licenseNumber)}</code></td>
                <td>${escapeHtml(req.specialization)}</td>
                <td><span class="badge pending">${req.status}</span></td>
                <td>
                    <button class="card action-btn" style="background: var(--emerald); color: white; border: none; padding: 8px 15px; margin-right: 8px;" onclick="approveDoctor(this)">
                        <i class="fa-solid fa-check"></i> Approve
                    </button>
                    <button class="card action-btn" style="background: var(--rose); color: white; border: none; padding: 8px 15px;" onclick="rejectDoctor(this)">
                        <i class="fa-solid fa-xmark"></i> Reject
                    </button>
                </td>
            </tr>
        `).join('');
        
    } catch (error) {
        console.error('Error loading doctor requests:', error);
        tbody.innerHTML = '<tr><td colspan="5" style="text-align: center; color: var(--rose);">Error loading data. Please refresh.</td></tr>';
    }
}

function simulateDoctorRequests() {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve([
                { id: '1', name: 'Dr. Sarah Jenkins', email: 'sarah.j@mednet.gov', licenseNumber: 'MC-892341', specialization: 'Cardiology', phone: '9876543210', status: 'pending' },
                { id: '2', name: 'Dr. Michael Chen', email: 'm.chen@hospital.io', licenseNumber: 'MC-771209', specialization: 'Pediatrics', phone: '9876543211', status: 'pending' }
            ]);
        }, 500);
    });
}

async function approveDoctor(button) {
    const row = button.closest('tr');
    const requestId = row.dataset.id;
    const doctorData = {
        name: row.dataset.name,
        email: row.dataset.email,
        specialization: row.dataset.specialization,
        phoneNumber: row.dataset.phone,
        licenseNumber: row.dataset.license
    };
    
    button.disabled = true;
    button.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
    
    try {
        // In production: Move from doctor_requests to doctors
        await simulateDoctorApproval(doctorData);
        
        // Remove row with animation
        gsap.to(row, { opacity: 0, duration: 0.3, onComplete: () => row.remove() });
        showToast(`${doctorData.name} has been approved`, 'success');
        
    } catch (error) {
        console.error('Error approving doctor:', error);
        showToast('Failed to approve doctor', 'error');
        button.disabled = false;
        button.innerHTML = '<i class="fa-solid fa-check"></i> Approve';
    }
}

async function rejectDoctor(button) {
    const row = button.closest('tr');
    const doctorName = row.dataset.name;
    
    button.disabled = true;
    button.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
    
    try {
        await simulateDoctorRejection(row.dataset.id);
        gsap.to(row, { opacity: 0, duration: 0.3, onComplete: () => row.remove() });
        showToast(`${doctorName} has been rejected`, 'info');
    } catch (error) {
        showToast('Failed to reject doctor', 'error');
        button.disabled = false;
        button.innerHTML = '<i class="fa-solid fa-xmark"></i> Reject';
    }
}

function simulateDoctorApproval(data) {
    return new Promise((resolve) => setTimeout(resolve, 800));
}

function simulateDoctorRejection(id) {
    return new Promise((resolve) => setTimeout(resolve, 800));
}

// Student Verification Functions
async function loadStudentRequests() {
    const tbody = document.querySelector('#student-table tbody');
    if (!tbody) return;
    
    tbody.innerHTML = '<tr><td colspan="6" style="text-align: center;"><i class="fa-solid fa-spinner fa-spin"></i> Loading verification requests...</td></tr>';
    
    try {
        const requests = await simulateStudentRequests();
        
        if (requests.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align: center;">No pending verification requests</td></tr>';
            return;
        }
        
        tbody.innerHTML = requests.map(req => `
            <tr data-id="${req.id}" data-email="${req.email}" data-name="${req.name}" data-college="${req.college}" data-course="${req.course}" data-year="${req.year}" data-phone="${req.phone}">
                <td>
                    <div class="user-cell">
                        <div class="user-avatar" style="background: linear-gradient(135deg, #10b981, #06b6d4);">${getInitials(req.name)}</div>
                        <div>
                            <p style="font-weight: 600;">${escapeHtml(req.name)}</p>
                            <p style="font-size: 0.75rem; color: var(--text-muted);">${escapeHtml(req.email)}</p>
                        </div>
                    </div>
                </td>
                <td><code style="background: rgba(255,255,255,0.05); padding: 4px 8px; border-radius: 5px;">${escapeHtml(req.studentId)}</code></td>
                <td>${escapeHtml(req.college)}</td>
                <td>${escapeHtml(req.course)}</td>
                <td><span class="badge pending">${req.status}</span></td>
                <td>
                    <button class="card action-btn" style="background: var(--emerald); color: white; border: none; padding: 8px 15px; margin-right: 8px;" onclick="approveStudent(this)">
                        <i class="fa-solid fa-check"></i> Grant Access
                    </button>
                    <button class="card action-btn" style="background: var(--rose); color: white; border: none; padding: 8px 15px;" onclick="rejectStudent(this)">
                        <i class="fa-solid fa-xmark"></i> Deny
                    </button>
                </td>
            </tr>
        `).join('');
        
    } catch (error) {
        console.error('Error loading student requests:', error);
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; color: var(--rose);">Error loading data. Please refresh.</td></tr>';
    }
}

function simulateStudentRequests() {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve([
                { id: '1', name: 'James Anderson', email: 'j.anderson@oxford.edu', studentId: 'ST-55612', college: 'Oxford Medical College', course: 'MBBS', year: '3rd Year', phone: '9876543212', status: 'pending' },
                { id: '2', name: 'Priya Patel', email: 'priya.p@health-inst.gov', studentId: 'ST-99201', college: 'National Health Inst.', course: 'MD', year: 'Final Year', phone: '9876543213', status: 'pending' }
            ]);
        }, 500);
    });
}

async function approveStudent(button) {
    const row = button.closest('tr');
    const studentName = row.dataset.name;
    
    button.disabled = true;
    button.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
    
    try {
        await simulateStudentApproval(row.dataset);
        gsap.to(row, { opacity: 0, duration: 0.3, onComplete: () => row.remove() });
        showToast(`${studentName} has been granted access`, 'success');
    } catch (error) {
        showToast('Failed to approve student', 'error');
        button.disabled = false;
        button.innerHTML = '<i class="fa-solid fa-check"></i> Grant Access';
    }
}

async function rejectStudent(button) {
    const row = button.closest('tr');
    const studentName = row.dataset.name;
    
    button.disabled = true;
    button.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>';
    
    try {
        await simulateStudentRejection(row.dataset.id);
        gsap.to(row, { opacity: 0, duration: 0.3, onComplete: () => row.remove() });
        showToast(`${studentName} has been denied`, 'info');
    } catch (error) {
        showToast('Failed to reject student', 'error');
        button.disabled = false;
        button.innerHTML = '<i class="fa-solid fa-xmark"></i> Deny';
    }
}

function simulateStudentApproval(data) {
    return new Promise((resolve) => setTimeout(resolve, 800));
}

function simulateStudentRejection(id) {
    return new Promise((resolve) => setTimeout(resolve, 800));
}

// Public Form Functions
function initDoctorApplyForm() {
    const form = document.getElementById('doctor-apply-form');
    if (form) {
        form.addEventListener('submit', handleDoctorApply);
    }
}

async function handleDoctorApply(e) {
    e.preventDefault();
    const submitBtn = e.target.querySelector('button[type="submit"]');
    const originalText = submitBtn.innerHTML;
    
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Submitting...';
    
    try {
        const formData = {
            name: document.getElementById('fullName').value,
            email: document.getElementById('email').value,
            phoneNumber: document.getElementById('phone').value,
            licenseNumber: document.getElementById('licenseNumber').value,
            specialization: document.getElementById('specialization').value,
            clinicName: document.getElementById('clinicName').value || '',
            proofUrl: 'pending_upload', // In production, upload file first
            status: 'pending'
        };
        
        // In production: await appwriteService.createDocument('doctor_requests', formData)
        await simulateFormSubmission();
        
        showToast('Application submitted successfully! Our team will review it within 48 hours.', 'success');
        e.target.reset();
        
    } catch (error) {
        console.error('Error submitting doctor application:', error);
        showToast('Failed to submit application. Please try again.', 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.innerHTML = originalText;
    }
}

function handleSpecialization(select) {
    const otherInput = document.getElementById('otherSpecialization');
    
    if (select.value === "Others") {
        otherInput.style.display = "block";
        otherInput.required = true;
    } else {
        otherInput.style.display = "none";
        otherInput.required = false;
    }
}

function initStudentApplyForm() {
    const form = document.getElementById('student-apply-form');
    if (form) {
        form.addEventListener('submit', handleStudentApply);
    }
}

async function handleStudentApply(e) {
    e.preventDefault();
    const submitBtn = e.target.querySelector('button[type="submit"]');
    const originalText = submitBtn.innerHTML;
    
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Submitting...';
    
    try {
        const formData = {
            name: document.getElementById('fullName').value,
            email: document.getElementById('email').value,
            phoneNumber: document.getElementById('phone').value,
            college: document.getElementById('college').value,
            course: document.getElementById('course').value,
            year: document.getElementById('year').value,
            proofUrl: 'pending_upload',
            status: 'pending'
        };
        
        await simulateFormSubmission();
        showToast('Application submitted successfully! Awaiting verification.', 'success');
        e.target.reset();
        
    } catch (error) {
        showToast('Failed to submit application. Please try again.', 'error');
    } finally {
        submitBtn.disabled = false;
        submitBtn.innerHTML = originalText;
    }
}

function simulateFormSubmission() {
    return new Promise((resolve) => setTimeout(resolve, 1500));
}

// Analytics Functions
async function loadAnalyticsData() {
    try {
        const stats = await simulateAnalyticsData();
        updateAnalyticsCharts(stats);
    } catch (error) {
        console.error('Error loading analytics:', error);
    }
}

function simulateAnalyticsData() {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve({
                diseaseTrend: [120, 190, 150, 280, 220, 310],
                regionalData: [300, 450, 200, 150],
                regions: ['North', 'South', 'East', 'West'],
                demographicData: { pediatric: 24, adult: 48, geriatric: 28 }
            });
        }, 500);
    });
}

function updateAnalyticsCharts(data) {
    // Check if Chart.js is loaded and update charts
    if (typeof Chart !== 'undefined') {
        // Disease Trend Chart
        const ctx1 = document.getElementById('diseaseTrendChart');
        if (ctx1 && window.diseaseChart) {
            window.diseaseChart.data.datasets[0].data = data.diseaseTrend;
            window.diseaseChart.update();
        }
        
        // Region Chart
        const ctx2 = document.getElementById('regionChart');
        if (ctx2 && window.regionChart) {
            window.regionChart.data.datasets[0].data = data.regionalData;
            window.regionChart.update();
        }
    }
}

// Heatmap Functions
async function loadHeatmapData() {
    try {
        const regionData = await simulateHeatmapData();
        updateHeatmapRegions(regionData);
    } catch (error) {
        console.error('Error loading heatmap:', error);
    }
}

function simulateHeatmapData() {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve([
                { zone: 'A1', risk: 'low' },
                { zone: 'A2', risk: 'medium' },
                { zone: 'A3', risk: 'low' },
                { zone: 'B1', risk: 'high' },
                { zone: 'B2', risk: 'low' },
                { zone: 'C1', risk: 'high' },
                { zone: 'C2', risk: 'medium' },
                { zone: 'C3', risk: 'low' }
            ]);
        }, 500);
    });
}

function updateHeatmapRegions(regions) {
    const regionBoxes = document.querySelectorAll('.region-box');
    regionBoxes.forEach((box, index) => {
        if (regions[index]) {
            const risk = regions[index].risk;
            if (risk === 'high') {
                box.style.borderColor = 'var(--rose)';
                box.querySelector('i')?.classList.add('fa-biohazard', 'fa-radiation');
            } else if (risk === 'medium') {
                box.style.borderColor = 'var(--amber)';
            } else {
                box.style.borderColor = 'var(--glass-border)';
            }
        }
    });
}

// Alerts Functions
async function loadAlertsData() {
    const alertContainer = document.querySelector('.alert-list');
    if (!alertContainer) return;
    
    alertContainer.innerHTML = '<div class="card" style="text-align: center;"><i class="fa-solid fa-spinner fa-spin"></i> Loading alerts...</div>';
    
    try {
        const alerts = await simulateAlertsData();
        
        if (alerts.length === 0) {
            alertContainer.innerHTML = '<div class="card" style="text-align: center;">No active alerts</div>';
            return;
        }
        
        alertContainer.innerHTML = alerts.map(alert => `
            <div class="card" style="display: flex; justify-content: space-between; align-items: center; border-left: 6px solid ${alert.severity === 'high' ? 'var(--rose)' : 'var(--amber)'};">
                <div>
                    <h3 style="color: ${alert.severity === 'high' ? 'var(--rose)' : 'var(--amber)'}; margin-bottom: 10px;">
                        <i class="fa-solid ${alert.icon}"></i> ${escapeHtml(alert.title)}
                    </h3>
                    <p style="color: var(--text-muted); max-width: 600px;">${escapeHtml(alert.description)}</p>
                </div>
                <button class="card" style="background: ${alert.severity === 'high' ? 'var(--rose)' : 'var(--amber)'}; color: white; border: none; padding: 12px 25px; font-weight: 700; cursor: pointer;" onclick="showToast('Response team dispatched', 'success')">
                    ${alert.buttonText}
                </button>
            </div>
        `).join('');
        
    } catch (error) {
        console.error('Error loading alerts:', error);
        alertContainer.innerHTML = '<div class="card" style="text-align: center; color: var(--rose);">Error loading alerts</div>';
    }
}

function simulateAlertsData() {
    return new Promise((resolve) => {
        setTimeout(() => {
            resolve([
                { title: 'High Dengue Cluster: Bangalore', description: 'AI Vector Analysis predicts 45% growth in next 24 hours. Recommended action: Emergency Fumigation & Resource Shift.', severity: 'high', icon: 'fa-biohazard', buttonText: 'Deploy Response' },
                { title: 'Seasonal Flu Warning: Delhi NCR', description: 'Pediatric centers at 85% capacity. Public health advisory dissemination recommended.', severity: 'medium', icon: 'fa-wind', buttonText: 'Issue Advisory' },
                { title: 'Cholera Risk: Mumbai South', description: 'Contamination detected in water supply nodes. Emergency medical camps required.', severity: 'high', icon: 'fa-droplet-slash', buttonText: 'Initialize Camps' }
            ]);
        }, 500);
    });
}

// Toast Notification
function showToast(message, type = 'success') {
    const container = document.getElementById('toast-container') || createToastContainer();
    const toast = document.createElement('div');
    toast.className = 'toast';
    const icon = type === 'success' ? 'fa-circle-check' : (type === 'error' ? 'fa-circle-exclamation' : 'fa-info-circle');
    const color = type === 'success' ? 'var(--emerald)' : (type === 'error' ? 'var(--rose)' : 'var(--amber)');
    
    toast.innerHTML = `
        <i class="fa-solid ${icon}" style="color: ${color}"></i>
        <span>${message}</span>
    `;
    
    container.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateX(20px)';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

function createToastContainer() {
    const container = document.createElement('div');
    container.className = 'toast-container';
    container.id = 'toast-container';
    document.body.appendChild(container);
    return container;
}

// Utility Functions
function getInitials(name) {
    return name.split(' ').map(n => n[0]).join('').toUpperCase().slice(0, 2);
}

function escapeHtml(str) {
    if (!str) return '';
    return str
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function updateRecentActivity(activities) {
    const activityContainer = document.querySelector('.alert-list');
    if (activityContainer && activities) {
        // Only update if it's the dashboard's activity section
        const dashboardActivity = document.querySelector('.dashboard-activity');
        if (dashboardActivity) {
            dashboardActivity.innerHTML = activities.map(act => `
                <div style="padding: 12px; background: rgba(255,255,255,0.03); border-radius: 10px; margin-bottom: 10px;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <span style="font-weight: 500;">${escapeHtml(act.name)}</span>
                        <span class="badge ${act.action === 'approved' ? 'approved' : (act.action === 'rejected' ? 'rejected' : 'pending')}" style="font-size: 0.7rem;">${act.action}</span>
                    </div>
                    <p style="font-size: 0.75rem; color: var(--text-muted); margin-top: 5px;">${act.time}</p>
                </div>
            `).join('');
        }
    }
}

document.getElementById('licenseUpload')?.addEventListener('change', function() {
    const fileName = this.files[0]?.name;
    if (fileName) {
        this.parentElement.querySelector('p').innerText = fileName;
    }
});

