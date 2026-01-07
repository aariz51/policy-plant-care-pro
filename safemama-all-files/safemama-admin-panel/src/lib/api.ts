const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:3001";

interface ApiResponse<T> {
    success: boolean;
    data?: T;
    error?: string;
}

async function fetchWithAuth<T>(
    endpoint: string,
    token: string,
    options: RequestInit = {}
): Promise<ApiResponse<T>> {
    try {
        console.log(`[Admin API] Fetching: ${API_BASE_URL}${endpoint}`);

        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${token}`,
                ...options.headers,
            },
        });

        console.log(`[Admin API] Response status: ${response.status}`);

        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            console.error(`[Admin API] Error:`, errorData);
            return {
                success: false,
                error: errorData.error || `HTTP error ${response.status}`,
            };
        }

        const jsonResponse = await response.json();
        console.log(`[Admin API] Response received`);

        // Backend returns {success: true, data: {...}} format
        // Extract the nested data if present
        if (jsonResponse.success && jsonResponse.data) {
            return { success: true, data: jsonResponse.data };
        }

        // If response doesn't have wrapper, return as-is
        return { success: true, data: jsonResponse as T };
    } catch (error) {
        console.error(`[Admin API] Fetch error:`, error);
        return {
            success: false,
            error: error instanceof Error ? error.message : "Unknown error",
        };
    }
}

// Admin API endpoints
export const adminApi = {
    // Dashboard stats
    getDashboardStats: (token: string) =>
        fetchWithAuth<DashboardStats>("/api/admin/dashboard-stats", token),

    // Users
    getUsers: (token: string, page = 1, limit = 20, search = "") =>
        fetchWithAuth<UsersResponse>(
            `/api/admin/users?page=${page}&limit=${limit}&search=${encodeURIComponent(search)}`,
            token
        ),

    getUserDetails: (token: string, userId: string) =>
        fetchWithAuth<UserDetails>(`/api/admin/users/${userId}`, token),

    // Feature usage
    getFeatureUsage: (token: string) =>
        fetchWithAuth<FeatureUsage>("/api/admin/feature-usage", token),

    // Recent activity
    getRecentActivity: (token: string, limit = 50) =>
        fetchWithAuth<ActivityItem[]>(`/api/admin/recent-activity?limit=${limit}`, token),

    // Revenue breakdown
    getRevenueBreakdown: (token: string) =>
        fetchWithAuth<RevenueBreakdown>("/api/admin/revenue-breakdown", token),

    // Cron jobs
    runCronJob: (token: string, job: "premium-expiry" | "image-cleanup") =>
        fetchWithAuth<CronJobResult>(`/api/admin/run-cron/${job}`, token, {
            method: "POST",
        }),

    getCronJobLogs: (token: string, limit = 20) =>
        fetchWithAuth<CronJobLog[]>(`/api/admin/cron-logs?limit=${limit}`, token),

    // Subscription sync endpoints
    syncAllSubscriptions: (token: string) =>
        fetchWithAuth<SyncResult>("/api/admin/sync-all-subscriptions", token, {
            method: "POST",
        }),

    syncUser: (token: string, userId: string) =>
        fetchWithAuth<UserSyncResult>(`/api/admin/sync-user/${userId}`, token, {
            method: "POST",
        }),

    getUserSubscriptions: (token: string, userId: string) =>
        fetchWithAuth<UserSubscriptions>(`/api/admin/user-subscriptions/${userId}`, token),

    grantPremium: (token: string, userId: string, tier: string, reason?: string) =>
        fetchWithAuth<GrantPremiumResult>(`/api/admin/grant-premium/${userId}`, token, {
            method: "POST",
            body: JSON.stringify({ tier, reason }),
        }),
};

export interface SyncResult {
    success: boolean;
    message: string;
    details: {
        synced: number;
        updated: number;
        noChange: number;
        notFound: number;
        failed: number;
    };
}

export interface UserSyncResult {
    userId: string;
    email: string;
    previousTier: string;
    currentTier: string;
    expiresAt: string | null;
    action: "updated" | "downgraded" | "no_change";
}

export interface UserSubscriptions {
    success: boolean;
    subscriptions: Array<{
        productId: string;
        purchaseDate: string;
        expiresDate: string;
        isActive: boolean;
        store: string;
        isSandbox: boolean;
    }>;
}

export interface GrantPremiumResult {
    userId: string;
    tier: string;
    expiresAt: string;
    reason?: string;
}


// Type definitions
export interface DashboardStats {
    totalUsers: number;
    premiumUsers: {
        weekly: number;
        monthly: number;
        yearly: number;
        total: number;
    };
    mrr: number;
    totalRevenue: number;
    featureUsage: {
        totalScans: number;
        totalAskExpert: number;
        totalGuides: number;
        totalDocumentAnalysis: number;
        totalPregnancyTests: number;
    };
    todayStats: {
        newUsers: number;
        newPremium: number;
        scansToday: number;
    };
}

export interface UsersResponse {
    users: UserSummary[];
    total: number;
    page: number;
    totalPages: number;
}

export interface UserSummary {
    id: string;
    email: string;
    fullName: string;
    membershipTier: string;
    createdAt: string;
    lastActivity: string;
    scanCount: number;
    askExpertCount: number;
}

export interface UserDetails extends UserSummary {
    phoneNumber?: string;
    subscriptionExpiresAt?: string;
    deviceId?: string;
    selectedTrimester?: string;
    dietaryPreference?: string;
    knownAllergies?: string[];
    usage: {
        scans: number;
        askExpert: number;
        guides: number;
        documentAnalysis: number;
        pregnancyTests: number;
        manualSearch: number;
    };
    recentScans: ScanRecord[];
    recentActivity: ActivityItem[];
}

export interface ScanRecord {
    id: string;
    productName: string;
    safetyLevel: string;
    scannedAt: string;
    imageUrl?: string;
}

export interface FeatureUsage {
    pregnancy_tools: {
        [tool: string]: number;
    };
    scanning: {
        total: number;
        byDay: { date: string; count: number }[];
    };
    askExpert: {
        total: number;
        byDay: { date: string; count: number }[];
    };
    documentAnalysis: {
        total: number;
        byType: { type: string; count: number }[];
    };
}

export interface ActivityItem {
    id: string;
    userId: string;
    userEmail?: string;
    eventType: string;
    eventData?: Record<string, unknown>;
    createdAt: string;
}

export interface RevenueBreakdown {
    mrr: number;
    arr: number;
    byTier: {
        weekly: { count: number; revenue: number };
        monthly: { count: number; revenue: number };
        yearly: { count: number; revenue: number };
    };
    history: {
        month: string;
        mrr: number;
        newSubscribers?: number;
    }[];
}

export interface CronJobResult {
    success: boolean;
    message: string;
    recordsProcessed: number;
    details?: unknown;
}

export interface CronJobLog {
    id: string;
    jobName: string;
    startedAt: string;
    completedAt?: string;
    status: "running" | "completed" | "failed";
    recordsProcessed: number;
    errorMessage?: string;
}
