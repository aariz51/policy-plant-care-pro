"use client";

import { useEffect, useState } from "react";
import { useAuthStore } from "@/lib/auth-store";
import { adminApi, ActivityItem } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { ScrollArea } from "@/components/ui/scroll-area";
import {
    Activity,
    Scan,
    MessageSquare,
    FileText,
    User,
    Crown,
    RefreshCw,
    Baby,
    LogIn
} from "lucide-react";
import { formatDistanceToNow } from "date-fns";

const eventIcons: Record<string, React.ElementType> = {
    scan: Scan,
    ask_expert: MessageSquare,
    document_analysis: FileText,
    pregnancy_tool: Baby,
    subscription: Crown,
    login: LogIn,
    signup: User,
};

const eventColors: Record<string, string> = {
    scan: "bg-pink-100 text-pink-600",
    ask_expert: "bg-blue-100 text-blue-600",
    document_analysis: "bg-purple-100 text-purple-600",
    pregnancy_tool: "bg-green-100 text-green-600",
    subscription: "bg-amber-100 text-amber-600",
    login: "bg-gray-100 text-gray-600",
    signup: "bg-emerald-100 text-emerald-600",
};

export default function ActivityPage() {
    const { session } = useAuthStore();
    const [activities, setActivities] = useState<ActivityItem[]>([]);
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);

    const fetchActivity = async (isRefresh = false) => {
        if (!session?.access_token) return;

        if (isRefresh) setRefreshing(true);
        else setLoading(true);

        const result = await adminApi.getRecentActivity(session.access_token, 100);

        if (result.success && result.data) {
            setActivities(result.data);
        }

        setLoading(false);
        setRefreshing(false);
    };

    useEffect(() => {
        fetchActivity();
    }, [session]);

    if (loading) {
        return <ActivitySkeleton />;
    }

    // Mock data if API not connected
    const displayActivities = activities.length > 0 ? activities : [
        { id: "1", userId: "u1", userEmail: "sarah@email.com", eventType: "scan", createdAt: new Date(Date.now() - 1000 * 60 * 5).toISOString() },
        { id: "2", userId: "u2", userEmail: "emma@email.com", eventType: "ask_expert", createdAt: new Date(Date.now() - 1000 * 60 * 15).toISOString() },
        { id: "3", userId: "u3", userEmail: "lisa@email.com", eventType: "subscription", eventData: { tier: "monthly" }, createdAt: new Date(Date.now() - 1000 * 60 * 30).toISOString() },
        { id: "4", userId: "u4", userEmail: "maria@email.com", eventType: "pregnancy_tool", eventData: { tool: "kick_counter" }, createdAt: new Date(Date.now() - 1000 * 60 * 45).toISOString() },
        { id: "5", userId: "u5", userEmail: "anna@email.com", eventType: "document_analysis", eventData: { type: "ultrasound" }, createdAt: new Date(Date.now() - 1000 * 60 * 60).toISOString() },
        { id: "6", userId: "u6", userEmail: "jane@email.com", eventType: "signup", createdAt: new Date(Date.now() - 1000 * 60 * 90).toISOString() },
        { id: "7", userId: "u7", userEmail: "kate@email.com", eventType: "scan", createdAt: new Date(Date.now() - 1000 * 60 * 120).toISOString() },
    ];

    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div className="flex items-center justify-between">
                <div>
                    <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                        <Activity className="h-8 w-8 text-purple-600" />
                        Activity Feed
                    </h1>
                    <p className="text-gray-500 mt-1">
                        Real-time activity across the SafeMama app
                    </p>
                </div>
                <Button
                    variant="outline"
                    onClick={() => fetchActivity(true)}
                    disabled={refreshing}
                >
                    <RefreshCw className={`h-4 w-4 mr-2 ${refreshing ? "animate-spin" : ""}`} />
                    Refresh
                </Button>
            </div>

            {/* Activity Feed */}
            <Card>
                <CardHeader>
                    <CardTitle>Recent Activity</CardTitle>
                    <CardDescription>
                        Latest {displayActivities.length} events from users
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <ScrollArea className="h-[600px] pr-4">
                        <div className="space-y-4">
                            {displayActivities.map((activity) => {
                                const Icon = eventIcons[activity.eventType] || Activity;
                                const colorClass = eventColors[activity.eventType] || "bg-gray-100 text-gray-600";

                                return (
                                    <div
                                        key={activity.id}
                                        className="flex items-start gap-4 p-4 border rounded-lg hover:bg-gray-50 transition-colors"
                                    >
                                        <div className={`h-10 w-10 rounded-lg flex items-center justify-center ${colorClass}`}>
                                            <Icon className="h-5 w-5" />
                                        </div>
                                        <div className="flex-1 min-w-0">
                                            <div className="flex items-center gap-2">
                                                <span className="font-medium text-gray-900">
                                                    {activity.userEmail || "Anonymous"}
                                                </span>
                                                <Badge variant="outline" className="text-xs">
                                                    {activity.eventType.replace(/_/g, " ")}
                                                </Badge>
                                            </div>
                                            <p className="text-sm text-gray-500 mt-1">
                                                {getActivityDescription(activity)}
                                            </p>
                                        </div>
                                        <div className="text-sm text-gray-400 whitespace-nowrap">
                                            {formatDistanceToNow(new Date(activity.createdAt), { addSuffix: true })}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </ScrollArea>
                </CardContent>
            </Card>
        </div>
    );
}

function getActivityDescription(activity: ActivityItem): string {
    const data = activity.eventData || {};

    switch (activity.eventType) {
        case "scan":
            return "Scanned a product";
        case "ask_expert":
            return "Asked a question to SafeMama AI";
        case "document_analysis":
            return `Analyzed a ${data.type || "document"}`;
        case "pregnancy_tool":
            return `Used the ${(data.tool as string)?.replace(/_/g, " ") || "pregnancy tool"}`;
        case "subscription":
            return `Upgraded to ${data.tier || "premium"} plan`;
        case "signup":
            return "Created a new account";
        case "login":
            return "Logged in to the app";
        default:
            return `Performed ${activity.eventType}`;
    }
}

function ActivitySkeleton() {
    return (
        <div className="space-y-6">
            <div className="flex items-center justify-between">
                <div>
                    <Skeleton className="h-9 w-48" />
                    <Skeleton className="h-5 w-64 mt-2" />
                </div>
                <Skeleton className="h-10 w-24" />
            </div>
            <Card>
                <CardHeader>
                    <Skeleton className="h-6 w-36" />
                </CardHeader>
                <CardContent>
                    <div className="space-y-4">
                        {[1, 2, 3, 4, 5].map((i) => (
                            <div key={i} className="flex items-start gap-4 p-4 border rounded-lg">
                                <Skeleton className="h-10 w-10 rounded-lg" />
                                <div className="flex-1">
                                    <Skeleton className="h-5 w-48" />
                                    <Skeleton className="h-4 w-64 mt-2" />
                                </div>
                                <Skeleton className="h-4 w-24" />
                            </div>
                        ))}
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
