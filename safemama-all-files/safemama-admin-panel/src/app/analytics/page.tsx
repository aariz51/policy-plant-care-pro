"use client";

import { useEffect, useState } from "react";
import { useAuthStore } from "@/lib/auth-store";
import { adminApi, FeatureUsage } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
    BarChart3,
    Scan,
    MessageSquare,
    FileText,
    Baby,
    Calculator,
    Scale,
    HeartPulse,
    CalendarCheck,
    Stethoscope,
    Pill,
    Syringe,
    ShoppingBag
} from "lucide-react";
import { formatNumber } from "@/lib/revenue";
import { ChartContainer, ChartTooltip, ChartTooltipContent } from "@/components/ui/chart";
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, ResponsiveContainer, LineChart, Line } from "recharts";

const pregnancyToolsConfig: Record<string, { label: string; icon: React.ElementType; color: string }> = {
    lmp_calculator: { label: "LMP Calculator", icon: Calculator, color: "#f472b6" },
    due_date_calculator: { label: "Due Date", icon: CalendarCheck, color: "#a78bfa" },
    kick_counter: { label: "Kick Counter", icon: Baby, color: "#60a5fa" },
    weight_tracker: { label: "Weight Tracker", icon: Scale, color: "#34d399" },
    contraction_timer: { label: "Contraction Timer", icon: HeartPulse, color: "#fb923c" },
    ttc_tracker: { label: "TTC Tracker", icon: CalendarCheck, color: "#f87171" },
    baby_name: { label: "Baby Name Gen", icon: Baby, color: "#c084fc" },
    birth_plan: { label: "Birth Plan", icon: FileText, color: "#22d3ee" },
    postpartum: { label: "Postpartum", icon: Stethoscope, color: "#4ade80" },
    vaccine_tracker: { label: "Vaccine Tracker", icon: Syringe, color: "#facc15" },
    hospital_bag: { label: "Hospital Bag", icon: ShoppingBag, color: "#f472b6" },
    medication_tracker: { label: "Medication", icon: Pill, color: "#a3e635" },
};

export default function AnalyticsPage() {
    const { session } = useAuthStore();
    const [featureUsage, setFeatureUsage] = useState<FeatureUsage | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchData() {
            if (!session?.access_token) return;

            setLoading(true);
            const result = await adminApi.getFeatureUsage(session.access_token);

            if (result.success && result.data) {
                setFeatureUsage(result.data);
            }
            setLoading(false);
        }

        fetchData();
    }, [session]);

    if (loading) {
        return <AnalyticsSkeleton />;
    }

    // Mock data if API not connected yet
    const mockUsage = featureUsage || {
        pregnancy_tools: {
            lmp_calculator: 450,
            due_date_calculator: 890,
            kick_counter: 320,
            weight_tracker: 210,
            contraction_timer: 78,
            ttc_tracker: 156,
            baby_name: 234,
            birth_plan: 89,
            postpartum: 67,
            vaccine_tracker: 45,
            hospital_bag: 112,
        },
        scanning: {
            total: 2500,
            byDay: [
                { date: "Mon", count: 320 },
                { date: "Tue", count: 410 },
                { date: "Wed", count: 380 },
                { date: "Thu", count: 350 },
                { date: "Fri", count: 420 },
                { date: "Sat", count: 290 },
                { date: "Sun", count: 330 },
            ],
        },
        askExpert: {
            total: 850,
            byDay: [
                { date: "Mon", count: 120 },
                { date: "Tue", count: 145 },
                { date: "Wed", count: 132 },
                { date: "Thu", count: 118 },
                { date: "Fri", count: 158 },
                { date: "Sat", count: 89 },
                { date: "Sun", count: 88 },
            ],
        },
        documentAnalysis: {
            total: 320,
            byType: [
                { type: "Ultrasound", count: 145 },
                { type: "Blood Test", count: 98 },
                { type: "Prescription", count: 52 },
                { type: "Other", count: 25 },
            ],
        },
    };

    // Prepare pregnancy tools chart data
    const toolsChartData = Object.entries(mockUsage.pregnancy_tools).map(([key, value]) => ({
        name: pregnancyToolsConfig[key]?.label || key,
        value: value as number,
        fill: pregnancyToolsConfig[key]?.color || "#94a3b8",
    }));

    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div>
                <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                    <BarChart3 className="h-8 w-8 text-purple-600" />
                    Analytics
                </h1>
                <p className="text-gray-500 mt-1">
                    Feature usage analytics across the SafeMama app
                </p>
            </div>

            <Tabs defaultValue="overview" className="space-y-4">
                <TabsList>
                    <TabsTrigger value="overview">Overview</TabsTrigger>
                    <TabsTrigger value="scanning">Scanning</TabsTrigger>
                    <TabsTrigger value="pregnancy-tools">Pregnancy Tools</TabsTrigger>
                    <TabsTrigger value="documents">Documents</TabsTrigger>
                </TabsList>

                {/* Overview Tab */}
                <TabsContent value="overview" className="space-y-4">
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                        <FeatureCard
                            icon={Scan}
                            title="Product Scans"
                            value={mockUsage.scanning.total}
                            color="pink"
                        />
                        <FeatureCard
                            icon={MessageSquare}
                            title="Ask Expert Queries"
                            value={mockUsage.askExpert.total}
                            color="blue"
                        />
                        <FeatureCard
                            icon={FileText}
                            title="Document Analyses"
                            value={mockUsage.documentAnalysis.total}
                            color="purple"
                        />
                        <FeatureCard
                            icon={Baby}
                            title="Pregnancy Tool Uses"
                            value={Object.values(mockUsage.pregnancy_tools).reduce((a, b) => (a as number) + (b as number), 0) as number}
                            color="green"
                        />
                    </div>

                    {/* Weekly Activity Chart */}
                    <Card>
                        <CardHeader>
                            <CardTitle>Weekly Activity</CardTitle>
                            <CardDescription>Scans and Ask Expert queries this week</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <ChartContainer
                                config={{
                                    scans: { label: "Scans", color: "#ec4899" },
                                    askExpert: { label: "Ask Expert", color: "#3b82f6" },
                                }}
                                className="h-[300px]"
                            >
                                <ResponsiveContainer width="100%" height="100%">
                                    <BarChart data={mockUsage.scanning.byDay.map((d, i) => ({
                                        ...d,
                                        askExpert: mockUsage.askExpert.byDay[i]?.count || 0,
                                    }))}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis dataKey="date" />
                                        <YAxis />
                                        <ChartTooltip content={<ChartTooltipContent />} />
                                        <Bar dataKey="count" name="Scans" fill="#ec4899" radius={4} />
                                        <Bar dataKey="askExpert" name="Ask Expert" fill="#3b82f6" radius={4} />
                                    </BarChart>
                                </ResponsiveContainer>
                            </ChartContainer>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Scanning Tab */}
                <TabsContent value="scanning" className="space-y-4">
                    <Card>
                        <CardHeader>
                            <CardTitle>Daily Scan Trend</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <ChartContainer
                                config={{ count: { label: "Scans", color: "#ec4899" } }}
                                className="h-[300px]"
                            >
                                <ResponsiveContainer width="100%" height="100%">
                                    <LineChart data={mockUsage.scanning.byDay}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis dataKey="date" />
                                        <YAxis />
                                        <ChartTooltip content={<ChartTooltipContent />} />
                                        <Line type="monotone" dataKey="count" stroke="#ec4899" strokeWidth={2} dot={{ r: 4 }} />
                                    </LineChart>
                                </ResponsiveContainer>
                            </ChartContainer>
                        </CardContent>
                    </Card>
                </TabsContent>

                {/* Pregnancy Tools Tab */}
                <TabsContent value="pregnancy-tools" className="space-y-4">
                    <Card>
                        <CardHeader>
                            <CardTitle>Pregnancy Tools Usage</CardTitle>
                            <CardDescription>Usage count for each pregnancy tool</CardDescription>
                        </CardHeader>
                        <CardContent>
                            <ChartContainer
                                config={{ value: { label: "Uses", color: "#a78bfa" } }}
                                className="h-[400px]"
                            >
                                <ResponsiveContainer width="100%" height="100%">
                                    <BarChart data={toolsChartData} layout="vertical">
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis type="number" />
                                        <YAxis dataKey="name" type="category" width={120} />
                                        <ChartTooltip content={<ChartTooltipContent />} />
                                        <Bar dataKey="value" radius={4} />
                                    </BarChart>
                                </ResponsiveContainer>
                            </ChartContainer>
                        </CardContent>
                    </Card>

                    {/* Tools Grid */}
                    <div className="grid gap-4 md:grid-cols-3 lg:grid-cols-4">
                        {Object.entries(mockUsage.pregnancy_tools).map(([key, value]) => {
                            const config = pregnancyToolsConfig[key];
                            if (!config) return null;
                            const Icon = config.icon;
                            return (
                                <Card key={key}>
                                    <CardContent className="pt-6">
                                        <div className="flex items-center gap-3">
                                            <div
                                                className="h-10 w-10 rounded-lg flex items-center justify-center"
                                                style={{ backgroundColor: `${config.color}20` }}
                                            >
                                                <Icon className="h-5 w-5" style={{ color: config.color }} />
                                            </div>
                                            <div>
                                                <div className="text-2xl font-bold">{formatNumber(value as number)}</div>
                                                <div className="text-sm text-gray-500">{config.label}</div>
                                            </div>
                                        </div>
                                    </CardContent>
                                </Card>
                            );
                        })}
                    </div>
                </TabsContent>

                {/* Documents Tab */}
                <TabsContent value="documents" className="space-y-4">
                    <Card>
                        <CardHeader>
                            <CardTitle>Document Analysis by Type</CardTitle>
                        </CardHeader>
                        <CardContent>
                            <ChartContainer
                                config={{ count: { label: "Analyses", color: "#8b5cf6" } }}
                                className="h-[300px]"
                            >
                                <ResponsiveContainer width="100%" height="100%">
                                    <BarChart data={mockUsage.documentAnalysis.byType}>
                                        <CartesianGrid strokeDasharray="3 3" />
                                        <XAxis dataKey="type" />
                                        <YAxis />
                                        <ChartTooltip content={<ChartTooltipContent />} />
                                        <Bar dataKey="count" fill="#8b5cf6" radius={4} />
                                    </BarChart>
                                </ResponsiveContainer>
                            </ChartContainer>
                        </CardContent>
                    </Card>
                </TabsContent>
            </Tabs>
        </div>
    );
}

function FeatureCard({
    icon: Icon,
    title,
    value,
    color
}: {
    icon: React.ElementType;
    title: string;
    value: number;
    color: string;
}) {
    const colorClasses: Record<string, string> = {
        pink: "bg-pink-100 text-pink-600",
        blue: "bg-blue-100 text-blue-600",
        green: "bg-green-100 text-green-600",
        purple: "bg-purple-100 text-purple-600",
    };

    return (
        <Card>
            <CardContent className="pt-6">
                <div className="flex items-center gap-3">
                    <div className={`h-12 w-12 rounded-lg flex items-center justify-center ${colorClasses[color]}`}>
                        <Icon className="h-6 w-6" />
                    </div>
                    <div>
                        <div className="text-2xl font-bold">{formatNumber(value)}</div>
                        <div className="text-sm text-gray-500">{title}</div>
                    </div>
                </div>
            </CardContent>
        </Card>
    );
}

function AnalyticsSkeleton() {
    return (
        <div className="space-y-6">
            <div>
                <Skeleton className="h-9 w-40" />
                <Skeleton className="h-5 w-60 mt-2" />
            </div>
            <Skeleton className="h-10 w-96" />
            <div className="grid gap-4 md:grid-cols-4">
                {[1, 2, 3, 4].map((i) => (
                    <Skeleton key={i} className="h-24 w-full" />
                ))}
            </div>
            <Skeleton className="h-80 w-full" />
        </div>
    );
}
