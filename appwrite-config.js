// Appwrite Configuration
const APPWRITE_ENDPOINT = 'https://sgp.cloud.appwrite.io/v1'; // Replace with your endpoint
const APPWRITE_PROJECT_ID = '69c8f07c00157b2d6d86'; // Replace with your project ID
const APPWRITE_DATABASE_ID = '69c8f0ac00115c11cfe0'; // Replace with your database ID

// Collection IDs
const COLLECTIONS = {
    DOCTOR_REQUESTS: 'doctor_requests',
    STUDENT_REQUESTS: 'student_requests',
    DOCTORS: 'doctors',
    STUDENTS: 'students',
    CONSULTATIONS: 'consultations',
    ANONYMIZED_STATS: 'anonymized_stats',
    AI_ALERTS: 'ai_alerts'
};

// Initialize Appwrite SDK
const sdk = window.Appwrite || window.appwrite;

// Helper functions
const appwriteService = {
    // Create document
    async createDocument(collectionId, data) {
        try {
            const response = await fetch(`${APPWRITE_ENDPOINT}/databases/${APPWRITE_DATABASE_ID}/collections/${collectionId}/documents`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Appwrite-Project': APPWRITE_PROJECT_ID,
                },
                body: JSON.stringify({
                    documentId: 'unique()',
                    data: data
                })
            });
            return await response.json();
        } catch (error) {
            console.error(`Error creating document in ${collectionId}:`, error);
            throw error;
        }
    },

    // Get documents with optional filter
    async getDocuments(collectionId, filters = []) {
        try {
            let url = `${APPWRITE_ENDPOINT}/databases/${APPWRITE_DATABASE_ID}/collections/${collectionId}/documents`;
            
            if (filters.length > 0) {
                url += `?queries=${filters.map(f => encodeURIComponent(f)).join('&')}`;
            }
            
            const response = await fetch(url, {
                headers: {
                    'X-Appwrite-Project': APPWRITE_PROJECT_ID,
                }
            });
            return await response.json();
        } catch (error) {
            console.error(`Error fetching documents from ${collectionId}:`, error);
            throw error;
        }
    },

    // Update document status
    async updateDocument(collectionId, documentId, data) {
        try {
            const response = await fetch(`${APPWRITE_ENDPOINT}/databases/${APPWRITE_DATABASE_ID}/collections/${collectionId}/documents/${documentId}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Appwrite-Project': APPWRITE_PROJECT_ID,
                },
                body: JSON.stringify({ data: data })
            });
            return await response.json();
        } catch (error) {
            console.error(`Error updating document in ${collectionId}:`, error);
            throw error;
        }
    },

    // Get count of documents
    async getCount(collectionId, filter = null) {
        try {
            let url = `${APPWRITE_ENDPOINT}/databases/${APPWRITE_DATABASE_ID}/collections/${collectionId}/documents`;
            if (filter) {
                url += `?queries=${encodeURIComponent(filter)}`;
            }
            
            const response = await fetch(url, {
                headers: {
                    'X-Appwrite-Project': APPWRITE_PROJECT_ID,
                }
            });
            const data = await response.json();
            return data.total || 0;
        } catch (error) {
            console.error(`Error getting count from ${collectionId}:`, error);
            return 0;
        }
    },

    // Upload file (simplified - in production use Appwrite Storage)
    async uploadFile(file, type) {
        // For hackathon demo, return a fake URL
        // In production, use Appwrite Storage bucket
        return new Promise((resolve) => {
            const reader = new FileReader();
            reader.onloadend = () => {
                resolve({
                    $id: Date.now().toString(),
                    url: reader.result,
                    name: file.name
                });
            };
            reader.readAsDataURL(file);
        });
    }
};