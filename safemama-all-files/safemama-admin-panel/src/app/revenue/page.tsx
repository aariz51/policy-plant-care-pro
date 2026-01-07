"use client";

import { useEffect, useState } from "react";
import { useAuthStore } from "@/lib/auth-store";
import { adminApi, RevenueBreakdown } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { DollarSign, TrendingUp, Crown, Calendar } from "lucide-react";
import { formatCurrency, PRICING } from "@/lib/revenue";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";

export default function RevenuePage() {
    const { session } = useAuthStore();
    const [revenue, setRevenue] = useState<RevenueBreakdown | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchData() {
            if (!session?.access_token) return;

            setLoading(true);
            const result = await adminApi.getRevenueBreakdown(session.access_token);

            if (result.success && result.data) {
                setRevenue(result.data);
            }
            setLoading(false);
        }

        fetchData();
    }, [session]);

    if (loading) {
        return <RevenueSkeleton />;
    }

    // Mock data if API not connected
    const revenueData = revenue || {
        mrr: 1247.85,
        arr: 14974.20,
        byTier: {
            weekly: { count: 25, revenue: 269.95 },
            monthly: { count: 180, revenue: 718.20 },
            yearly: { count: 85, revenue: 3399.15 },
        },
        history: [
            { month: "Aug", mrr: 850 },
            { month: "Sep", mrr: 920 },
            { month: "Oct", mrr: 1050 },
            { month: "Nov", mrr: 1180 },
            { month: "Dec", mrr: 1247.85 },
        ],
    };

    const totalSubscribers =
        revenueData.byTier.weekly.count +
        revenueData.byTier.monthly.count +
        revenueData.byTier.yearly.count;

    const pieData = [
        { name: "Weekly", value: revenueData.byTier.weekly.count, color: "#3b82f6" },
        { name: "Monthly", value: revenueData.byTier.monthly.count, color: "#a855f7" },
        { name: "Yearly", value: revenueData.byTier.yearly.count, color: "#f59e0b" },
    ];

    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div>
                <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                    <DollarSign className="h-8 w-8 text-green-600" />
                    Revenue
                </h1>
                <p className="text-gray-500 mt-1">
                    Revenue metrics and subscription analytics (in USD)
                </p>
            </div>

            {/* Key Metrics */}
            <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium text-gray-500">
                            Monthly Recurring Revenue
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-3xl font-bold text-green-600">
                            {formatCurrency(revenueData.mrr)}
                        </div>
                        <p className="text-xs text-gray-500 mt-1">MRR from all subscribers</p>
                    </CardContent>
                </Card>

                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium text-gray-500">
                            Annual Recurring Revenue
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-3xl font-bold text-blue-600">
                            {formatCurrency(revenueData.arr)}
                        </div>
                        <p className="text-xs text-gray-500 mt-1">MRR × 12</p>
                    </CardContent>
                </Card>

                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium text-gray-500">
                            Total Subscribers
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-3xl font-bold text-purple-600">
                            {totalSubscribers}
                        </div>
                        <p className="text-xs text-gray-500 mt-1">Active paid members</p>
                    </CardContent>
                </Card>

                <Card>
                    <CardHeader className="pb-2">
                        <CardTitle className="text-sm font-medium text-gray-500">
                            Avg Revenue Per User
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="text-3xl font-bold text-amber-600">
                            {formatCurrency(totalSubscribers > 0 ? revenueData.mrr / totalSubscribers : 0)}
                        </div>
                        <p className="text-xs text-gray-500 mt-1">ARPU per month</p>
                    </CardContent>
                </Card>
            </div>

            {/* Pricing Reference */}
            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Crown className="h-5 w-5 text-amber-500" />
                        Pricing Tiers (USD)
                    </CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4 md:grid-cols-3">
                        <div className="p-4 bg-blue-50 rounded-lg border border-blue-100">
                            <div className="text-sm font-medium text-blue-600">Weekly Plan</div>
                            <div className="text-2xl font-bold text-gray-900 mt-1">
                                ${PRICING.weekly}
                            </div>
                            <div className="text-sm text-gray-500 mt-1">
                                {revenueData.byTier.weekly.count} subscribers
                            </div>
                            <div className="text-xs text-gray-400 mt-1">
                                MRR contribution: {formatCurrency(revenueData.byTier.weekly.count * PRICING.weekly * 4.33)}
                            </div>
                        </div>
                        <div className="p-4 bg-purple-50 rounded-lg border border-purple-100">
                            <div className="text-sm font-medium text-purple-600">Monthly Plan</div>
                            <div className="text-2xl font-bold text-gray-900 mt-1">
                                ${PRICING.monthly}
                            </div>
                            <div className="text-sm text-gray-500 mt-1">
                                {revenueData.byTier.monthly.count} subscribers
                            </div>
                            <div className="text-xs text-gray-400 mt-1">
                                MRR contribution: {formatCurrency(revenueData.byTier.monthly.count * PRICING.monthly)}
                            </div>
                        </div>
                        <div className="p-4 bg-amber-50 rounded-lg border border-amber-100">
                            <div className="text-sm font-medium text-amber-600">Yearly Plan</div>
                            <div className="text-2xl font-bold text-gray-900 mt-1">
                                ${PRICING.yearly}
                            </div>
                            <div className="text-sm text-gray-500 mt-1">
                                {revenueData.byTier.yearly.count} subscribers
                            </div>
                            <div className="text-xs text-gray-400 mt-1">
                                MRR contribution: {formatCurrency(revenueData.byTier.yearly.count * (PRICING.yearly / 12))}
                            </div>
                        </div>
                    </div>
                </CardContent>
            </Card>

            <div className="grid gap-6 lg:grid-cols-2">
                {/* MRR Trend */}
                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <TrendingUp className="h-5 w-5 text-green-500" />
                            MRR Trend
                        </CardTitle>
                        <CardDescription>Monthly recurring revenue over time</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <ChartContainer
                            config={{ mrr: { label: "MRR", color: "#22c55e" } }}
                            className="h-[250px]"
                        >
                            <ResponsiveContainer width="100%" height="100%">
                                <AreaChart data={revenueData.history}>
                                    <CartesianGrid strokeDasharray="3 3" />
                                    <XAxis dataKey="month" />
                                    <YAxis />
                                    <ChartTooltip content={<ChartTooltipContent />} />
                                    <Area
                                        type="monotone"
                                        dataKey="mrr"
                                        stroke="#22c55e"
                                        fill="#dcfce7"
                                        strokeWidth={2}
                                    />
                                </AreaChart>
                            </ResponsiveContainer>
                        </ChartContainer>
                    </CardContent>
                </Card>

                {/* Subscriber Distribution */}
                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Calendar className="h-5 w-5 text-purple-500" />
                            Subscriber Distribution
                        </CardTitle>
                        <CardDescription>Breakdown by plan type</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <ChartContainer
                            config={{}}
                            className="h-[250px]"
                        >
                            <ResponsiveContainer width="100%" height="100%">
                                <PieChart>
                                    <Pie
                                        data={pieData}
                                        cx="50%"
                                        cy="50%"
                                        innerRadius={60}
                                        outerRadius={80}
                                        paddingAngle={5}
                                        dataKey="value"
                                    >
                                        {pieData.map((entry, index) => (
                                            <Cell key={`cell-${index}`} fill={entry.color} />
                                        ))}
                                    </Pie>
                                    <ChartTooltip content={<ChartTooltipContent />} />
                                </PieChart>
                            </ResponsiveContainer>
                        </ChartContainer>
                        <div className="flex justify-center gap-6 mt-4">
                            {pieData.map((item) => (
                                <div key={item.name} className="flex items-center gap-2">
                                    <div
                                        className="w-3 h-3 rounded-full"
                                        style={{ backgroundColor: item.color }}
                                    />
                                    <span className="text-sm text-gray-600">
                                        {item.name}: {item.value}
                                    </span>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}

function RevenueSkeleton() {
    return (
        <div className="space-y-6">
            <div>
                <Skeleton className="h-9 w-40" />
                <Skeleton className="h-5 w-60 mt-2" />
            </div>
            <div className="grid gap-4 md:grid-cols-4">
                {[1, 2, 3, 4].map((i) => (
                    <Skeleton key={i} className="h-28 w-full" />
                ))}
            </div>
            <Skeleton className="h-40 w-full" />
            <div className="grid gap-6 lg:grid-cols-2">
                <Skeleton className="h-80 w-full" />
                <Skeleton className="h-80 w-full" />
            </div>
        </div>
    );
}
