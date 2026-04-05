// Appwrite Configuration - Complete with EmailJS Integration
const APPWRITE_ENDPOINT = 'https://sgp.cloud.appwrite.io/v1';
const APPWRITE_PROJECT_ID = '69c8f07c00157b2d6d86';
const APPWRITE_DATABASE_ID = '69c8f0ac00115c11cfe0';

// CORS Proxy
const CORS_PROXY = 'https://cors-anywhere.herokuapp.com/';

// EmailJS Configuration - REPLACE WITH YOUR ACTUAL KEYS
const EMAILJS_CONFIG = {
    publicKey: 'Y4Q9HTnDx7aL6uRGLG',     // Get from EmailJS Dashboard → Account → API Keys
    serviceId: 'service_yqt9db8',     // Get from EmailJS Dashboard → Email Services
    templateId: 'template_vi4w8bp'    // Get from EmailJS Dashboard → Email Templates
};

const appwriteService = {
    generateId() {
        return 'doc_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    },

    // Initialize EmailJS
    initEmailJS() {
        if (typeof emailjs !== 'undefined' && !window.emailjsInitialized) {
            emailjs.init(EMAILJS_CONFIG.publicKey);
            window.emailjsInitialized = true;
            console.log('✅ EmailJS initialized');
        }
    },

    // Create document (Public submission)
    async createDocument(collectionId, data) {
        const url = `${CORS_PROXY}${APPWRITE_ENDPOINT}/databases/${APPWRITE_DATABASE_ID}/collections/${collectionId}/documents`;
        
        const requestBody = {
            documentId: this.generateId(),
            data: data
        };
        
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Appwrite-Project': APPWRITE_PROJECT_ID,
                },
                body: JSON.stringify(requestBody)
            });

            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`HTTP ${response.status}: ${errorText}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Create error:', error);
            throw error;
        }
    },

    // Get documents (Admin only)
    async getDocuments(collectionId) {
        const isLoggedIn = localStorage.getItem('adminLoggedIn');
        if (!isLoggedIn) throw new Error('Admin login required');

        const url = `${CORS_PROXY}${APPWRITE_ENDPOINT}/databases/${APPWRITE_DATABASE_ID}/collections/${collectionId}/documents`;
        
        try {
            const response = await fetch(url, {
                method: 'GET',
                headers: { 'X-Appwrite-Project': APPWRITE_PROJECT_ID }
            });

            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            const result = await response.json();
            return result.documents || [];
        } catch (error) {
            console.error('Fetch error:', error);
            return [];
        }
    },

    // Update document (Admin only)
    async updateDocument(collectionId, documentId, data) {
        const isLoggedIn = localStorage.getItem('adminLoggedIn');
        if (!isLoggedIn) throw new Error('Admin login required');

        const url = `${CORS_PROXY}${APPWRITE_ENDPOINT}/databases/${APPWRITE_DATABASE_ID}/collections/${collectionId}/documents/${documentId}`;
        
        try {
            const response = await fetch(url, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Appwrite-Project': APPWRITE_PROJECT_ID,
                },
                body: JSON.stringify({ data: data })
            });

            if (!response.ok) throw new Error(`HTTP ${response.status}`);
            return await response.json();
        } catch (error) {
            console.error('Update error:', error);
            throw error;
        }
    },

    // REAL EMAIL NOTIFICATION using EmailJS
    async sendEmailNotification(to, subject, message, type = 'status') {
        console.log(`📧 Sending email to: ${to}`);
        console.log(`Subject: ${subject}`);
        console.log(`Message: ${message}`);
        
        this.initEmailJS();
        
        // Extract name from email (simple approach)
        const recipientName = to.split('@')[0];
        
        // Determine email styling based on type
        let color, title;
        switch(type) {
            case 'approved':
                color = '#10b981';
                title = '✅ Application Approved!';
                break;
            case 'rejected':
                color = '#f43f5e';
                title = '❌ Application Update';
                break;
            default:
                color = '#8b5cf6';
                title = '📝 Status Update';
        }
        
        // Prepare data for Contact Us template
        const templateData = {
            to_name: recipientName,
            email: to,
            subject: subject,
            message: message,
            color: color,
            title: title
        };
        
        try {
            const response = await emailjs.send(
                EMAILJS_CONFIG.serviceId,
                EMAILJS_CONFIG.templateId,
                templateData
            );
            console.log('✅ Email sent successfully!', response);
            return { success: true, response: response };
        } catch (error) {
            console.error('❌ Email failed:', error);
            // Don't throw - app should continue working even if email fails
            return { success: false, error: error.text || error.message };
        }
    },

    // Helper: Send application status email with proper formatting
    async sendApplicationStatusEmail(email, applicantName, status, remarks = '') {
        let subject = '';
        let message = '';
        
        switch(status) {
            case 'approved':
                subject = '✅ Application Approved - MediBridge AI';
                message = `Dear ${applicantName},\n\nCongratulations! Your verification application has been APPROVED.\n\n${remarks ? `Remarks: ${remarks}\n\n` : ''}You can now access the MediBridge AI portal with your registered email.\n\nThank you for joining India's national healthcare network.\n\nBest regards,\nMediBridge AI Team\nMinistry of Health & Family Welfare`;
                break;
            case 'rejected':
                subject = 'Application Update - MediBridge AI';
                message = `Dear ${applicantName},\n\nThank you for your interest in MediBridge AI.\n\nAfter careful review, your verification application has been REJECTED.\n\nReason: ${remarks || 'Does not meet verification criteria'}\n\nIf you believe this is an error, please contact our support team at support@medibridge.gov.in\n\nBest regards,\nMediBridge AI Team`;
                break;
            default:
                subject = 'Application Received - MediBridge AI';
                message = `Dear ${applicantName},\n\nYour verification application has been received and is under review.\n\nStatus: ${status.toUpperCase()}\n\nYou will be notified via email once a decision is made.\n\nThank you for your patience.\n\nBest regards,\nMediBridge AI Team`;
        }
        
        return await this.sendEmailNotification(email, subject, message, status);
    },


// Check if user has set password
async hasUserSetPassword(email, role) {
    const collectionId = role === 'doctor' ? 'doctors' : 'students';
    const users = await this.getDocuments(collectionId);
    const user = users.find(u => u.email === email);
    return user?.hasSetPassword === true;
}

};

// Auto-initialize when page loads
if (typeof window !== 'undefined') {
    // Small delay to ensure emailjs is loaded
    setTimeout(() => {
        if (typeof emailjs !== 'undefined') {
            appwriteService.initEmailJS();
        }
    }, 500);
}

console.log('✅ Appwrite service with EmailJS ready');

