"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuthStore } from "@/lib/auth-store";
import { adminApi, UserDetails } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { Separator } from "@/components/ui/separator";
import {
    ArrowLeft,
    User,
    Crown,
    Mail,
    Phone,
    Calendar,
    Scan,
    MessageSquare,
    BookOpen,
    FileText,
    Baby,
    Search
} from "lucide-react";
import { formatDistanceToNow, format } from "date-fns";

export default function UserDetailsPage() {
    const params = useParams();
    const router = useRouter();
    const { session } = useAuthStore();
    const [user, setUser] = useState<UserDetails | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        async function fetchUser() {
            if (!session?.access_token || !params.id) return;

            setLoading(true);
            const result = await adminApi.getUserDetails(session.access_token, params.id as string);

            if (result.success && result.data) {
                setUser(result.data);
            }
            setLoading(false);
        }

        fetchUser();
    }, [session, params.id]);

    if (loading) {
        return <UserDetailsSkeleton />;
    }

    if (!user) {
        return (
            <div className="text-center py-10">
                <p className="text-gray-500">User not found</p>
                <Button variant="link" onClick={() => router.push("/users")}>
                    Back to Users
                </Button>
            </div>
        );
    }

    const tierColors: Record<string, string> = {
        free: "bg-gray-100 text-gray-700",
        premium_weekly: "bg-blue-100 text-blue-700",
        premium_monthly: "bg-purple-100 text-purple-700",
        premium_yearly: "bg-amber-100 text-amber-700",
    };

    return (
        <div className="space-y-6">
            {/* Back Button */}
            <Button
                variant="ghost"
                onClick={() => router.push("/users")}
                className="gap-2"
            >
                <ArrowLeft className="h-4 w-4" />
                Back to Users
            </Button>

            {/* User Header */}
            <div className="flex items-start gap-6">
                <div className="h-20 w-20 rounded-full bg-gradient-to-br from-pink-100 to-purple-100 flex items-center justify-center">
                    <User className="h-10 w-10 text-purple-600" />
                </div>
                <div className="flex-1">
                    <div className="flex items-center gap-3">
                        <h1 className="text-2xl font-bold text-gray-900">
                            {user.fullName || "Unknown User"}
                        </h1>
                        <Badge className={tierColors[user.membershipTier] || "bg-gray-100"}>
                            {user.membershipTier.includes("premium") && <Crown className="h-3 w-3 mr-1" />}
                            {user.membershipTier}
                        </Badge>
                    </div>
                    <div className="flex items-center gap-4 mt-2 text-gray-500">
                        <span className="flex items-center gap-1">
                            <Mail className="h-4 w-4" />
                            {user.email}
                        </span>
                        {user.phoneNumber && (
                            <span className="flex items-center gap-1">
                                <Phone className="h-4 w-4" />
                                {user.phoneNumber}
                            </span>
                        )}
                    </div>
                    <div className="flex items-center gap-4 mt-2 text-sm text-gray-400">
                        <span>Joined {formatDistanceToNow(new Date(user.createdAt), { addSuffix: true })}</span>
                        <span>Last active {user.lastActivity
                            ? formatDistanceToNow(new Date(user.lastActivity), { addSuffix: true })
                            : "never"}</span>
                    </div>
                </div>
            </div>

            <Separator />

            {/* Subscription Info */}
            {user.membershipTier !== "free" && user.subscriptionExpiresAt && (
                <Card>
                    <CardHeader>
                        <CardTitle className="flex items-center gap-2">
                            <Crown className="h-5 w-5 text-amber-500" />
                            Subscription Details
                        </CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="grid gap-4 md:grid-cols-2">
                            <div>
                                <div className="text-sm text-gray-500">Plan</div>
                                <div className="font-medium capitalize">
                                    {user.membershipTier.replace("premium_", "")} Premium
                                </div>
                            </div>
                            <div>
                                <div className="text-sm text-gray-500">Expires</div>
                                <div className="font-medium">
                                    {format(new Date(user.subscriptionExpiresAt), "PPP")}
                                </div>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            )}

            {/* Usage Statistics */}
            <Card>
                <CardHeader>
                    <CardTitle>Feature Usage</CardTitle>
                    <CardDescription>How this user has used SafeMama features</CardDescription>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4 md:grid-cols-3 lg:grid-cols-6">
                        <UsageItem icon={Scan} label="Scans" value={user.usage.scans} color="pink" />
                        <UsageItem icon={MessageSquare} label="Ask Expert" value={user.usage.askExpert} color="blue" />
                        <UsageItem icon={BookOpen} label="Guides" value={user.usage.guides} color="green" />
                        <UsageItem icon={FileText} label="Doc Analysis" value={user.usage.documentAnalysis} color="purple" />
                        <UsageItem icon={Baby} label="Preg. Tests" value={user.usage.pregnancyTests} color="amber" />
                        <UsageItem icon={Search} label="Searches" value={user.usage.manualSearch} color="gray" />
                    </div>
                </CardContent>
            </Card>

            {/* Profile Details */}
            <Card>
                <CardHeader>
                    <CardTitle>Profile Information</CardTitle>
                </CardHeader>
                <CardContent>
                    <div className="grid gap-4 md:grid-cols-2">
                        {user.selectedTrimester && (
                            <div>
                                <div className="text-sm text-gray-500">Trimester</div>
                                <div className="font-medium">{user.selectedTrimester}</div>
                            </div>
                        )}
                        {user.dietaryPreference && (
                            <div>
                                <div className="text-sm text-gray-500">Dietary Preference</div>
                                <div className="font-medium">{user.dietaryPreference}</div>
                            </div>
                        )}
                        {user.knownAllergies && user.knownAllergies.length > 0 && (
                            <div className="md:col-span-2">
                                <div className="text-sm text-gray-500">Known Allergies</div>
                                <div className="flex gap-2 mt-1">
                                    {user.knownAllergies.map((allergy, i) => (
                                        <Badge key={i} variant="outline">{allergy}</Badge>
                                    ))}
                                </div>
                            </div>
                        )}
                    </div>
                </CardContent>
            </Card>

            {/* Recent Scans */}
            {user.recentScans && user.recentScans.length > 0 && (
                <Card>
                    <CardHeader>
                        <CardTitle>Recent Scans</CardTitle>
                    </CardHeader>
                    <CardContent>
                        <div className="space-y-3">
                            {user.recentScans.slice(0, 5).map((scan) => (
                                <div key={scan.id} className="flex items-center justify-between p-3 border rounded-lg">
                                    <div>
                                        <div className="font-medium">{scan.productName}</div>
                                        <div className="text-sm text-gray-500">
                                            {formatDistanceToNow(new Date(scan.scannedAt), { addSuffix: true })}
                                        </div>
                                    </div>
                                    <Badge
                                        className={
                                            scan.safetyLevel === "safe" ? "bg-green-100 text-green-700" :
                                                scan.safetyLevel === "avoid" ? "bg-red-100 text-red-700" :
                                                    "bg-yellow-100 text-yellow-700"
                                        }
                                    >
                                        {scan.safetyLevel}
                                    </Badge>
                                </div>
                            ))}
                        </div>
                    </CardContent>
                </Card>
            )}
        </div>
    );
}

function UsageItem({
    icon: Icon,
    label,
    value,
    color
}: {
    icon: React.ElementType;
    label: string;
    value: number;
    color: string;
}) {
    const colorClasses: Record<string, string> = {
        pink: "bg-pink-100 text-pink-600",
        blue: "bg-blue-100 text-blue-600",
        green: "bg-green-100 text-green-600",
        purple: "bg-purple-100 text-purple-600",
        amber: "bg-amber-100 text-amber-600",
        gray: "bg-gray-100 text-gray-600",
    };

    return (
        <div className="text-center p-4 border rounded-lg">
            <div className={`h-10 w-10 mx-auto rounded-lg flex items-center justify-center ${colorClasses[color]}`}>
                <Icon className="h-5 w-5" />
            </div>
            <div className="text-2xl font-bold mt-2">{value}</div>
            <div className="text-xs text-gray-500">{label}</div>
        </div>
    );
}

function UserDetailsSkeleton() {
    return (
        <div className="space-y-6">
            <Skeleton className="h-10 w-32" />
            <div className="flex items-start gap-6">
                <Skeleton className="h-20 w-20 rounded-full" />
                <div className="flex-1">
                    <Skeleton className="h-8 w-48" />
                    <Skeleton className="h-4 w-64 mt-2" />
                    <Skeleton className="h-4 w-32 mt-2" />
                </div>
            </div>
            <Skeleton className="h-40 w-full" />
            <Skeleton className="h-32 w-full" />
        </div>
    );
}
