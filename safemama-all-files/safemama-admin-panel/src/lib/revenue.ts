// Pricing in USD
export const PRICING = {
    weekly: 2.49,
    monthly: 3.99,
    yearly: 39.99,
} as const;

// Calculate MRR from subscriber counts
export function calculateMRR(premiumUsers: {
    weekly: number;
    monthly: number;
    yearly: number;
}): number {
    // Convert weekly to monthly: weekly * 4.33 (average weeks per month)
    const weeklyMRR = premiumUsers.weekly * PRICING.weekly * 4.33;
    // Monthly is direct MRR
    const monthlyMRR = premiumUsers.monthly * PRICING.monthly;
    // Convert yearly to monthly: yearly / 12
    const yearlyMRR = premiumUsers.yearly * (PRICING.yearly / 12);

    return Math.round((weeklyMRR + monthlyMRR + yearlyMRR) * 100) / 100;
}

// Calculate total revenue from subscriber history
export function calculateTotalRevenue(
    weeklyPurchases: number,
    monthlyPurchases: number,
    yearlyPurchases: number
): number {
    return Math.round(
        (weeklyPurchases * PRICING.weekly +
            monthlyPurchases * PRICING.monthly +
            yearlyPurchases * PRICING.yearly) * 100
    ) / 100;
}

// Format currency
export function formatCurrency(amount: number): string {
    return new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD",
    }).format(amount);
}

// Format large numbers
export function formatNumber(num: number): string {
    if (num >= 1000000) {
        return (num / 1000000).toFixed(1) + "M";
    }
    if (num >= 1000) {
        return (num / 1000).toFixed(1) + "K";
    }
    return num.toString();
}

// Calculate percentage change
export function calculatePercentageChange(current: number, previous: number): number {
    if (previous === 0) return current > 0 ? 100 : 0;
    return Math.round(((current - previous) / previous) * 100 * 10) / 10;
}
