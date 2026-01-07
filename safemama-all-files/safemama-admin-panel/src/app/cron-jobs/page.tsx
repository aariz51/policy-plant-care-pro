"use client";

import { useEffect, useState } from "react";
import { useAuthStore } from "@/lib/auth-store";
import { adminApi, CronJobLog, CronJobResult } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
    Clock,
    Play,
    CheckCircle,
    XCircle,
    Loader2,
    Trash2,
    Crown,
    AlertCircle
} from "lucide-react";
import { formatDistanceToNow, format } from "date-fns";
import { toast } from "sonner";

export default function CronJobsPage() {
    const { session } = useAuthStore();
    const [logs, setLogs] = useState<CronJobLog[]>([]);
    const [loading, setLoading] = useState(true);
    const [runningJob, setRunningJob] = useState<string | null>(null);

    useEffect(() => {
        fetchLogs();
    }, [session]);

    const fetchLogs = async () => {
        if (!session?.access_token) return;

        setLoading(true);
        const result = await adminApi.getCronJobLogs(session.access_token, 20);

        if (result.success && result.data) {
            setLogs(result.data);
        }
        setLoading(false);
    };

    const runCronJob = async (job: "premium-expiry" | "image-cleanup") => {
        if (!session?.access_token) return;

        setRunningJob(job);
        const result = await adminApi.runCronJob(session.access_token, job);

        if (result.success && result.data) {
            toast.success(`Cron job completed: ${result.data.message}`);
            fetchLogs();
        } else {
            toast.error(result.error || "Failed to run cron job");
        }
        setRunningJob(null);
    };

    // Mock logs if API not connected
    const displayLogs = logs.length > 0 ? logs : [
        { id: "1", jobName: "premium-expiry", startedAt: new Date(Date.now() - 1000 * 60 * 60 * 24).toISOString(), completedAt: new Date(Date.now() - 1000 * 60 * 60 * 24 + 5000).toISOString(), status: "completed" as const, recordsProcessed: 12 },
        { id: "2", jobName: "image-cleanup", startedAt: new Date(Date.now() - 1000 * 60 * 60 * 48).toISOString(), completedAt: new Date(Date.now() - 1000 * 60 * 60 * 48 + 15000).toISOString(), status: "completed" as const, recordsProcessed: 45 },
        { id: "3", jobName: "premium-expiry", startedAt: new Date(Date.now() - 1000 * 60 * 60 * 72).toISOString(), completedAt: new Date(Date.now() - 1000 * 60 * 60 * 72 + 3000).toISOString(), status: "completed" as const, recordsProcessed: 8 },
    ];

    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div>
                <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                    <Clock className="h-8 w-8 text-purple-600" />
                    Cron Jobs
                </h1>
                <p className="text-gray-500 mt-1">
                    Automated scheduled tasks for SafeMama backend
                </p>
            </div>

            {/* Cron Job Cards */}
            <div className="grid gap-6 md:grid-cols-2">
                {/* Premium Expiry Check */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="h-12 w-12 rounded-lg bg-amber-100 flex items-center justify-center">
                                    <Crown className="h-6 w-6 text-amber-600" />
                                </div>
                                <div>
                                    <CardTitle>Premium Expiry Check</CardTitle>
                                    <CardDescription>Runs daily at midnight</CardDescription>
                                </div>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="text-sm text-gray-600 space-y-2">
                            <p>This job:</p>
                            <ul className="list-disc list-inside space-y-1 text-gray-500">
                                <li>Checks all premium users with expired subscriptions</li>
                                <li>Adds 1-day grace period from expiry date</li>
                                <li>Verifies renewal via RevenueCat API</li>
                                <li>Downgrades to free tier if not renewed</li>
                            </ul>
                        </div>
                        <Button
                            onClick={() => runCronJob("premium-expiry")}
                            disabled={runningJob !== null}
                            className="w-full"
                        >
                            {runningJob === "premium-expiry" ? (
                                <>
                                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                                    Running...
                                </>
                            ) : (
                                <>
                                    <Play className="h-4 w-4 mr-2" />
                                    Run Now
                                </>
                            )}
                        </Button>
                    </CardContent>
                </Card>

                {/* Image Cleanup */}
                <Card>
                    <CardHeader>
                        <div className="flex items-center justify-between">
                            <div className="flex items-center gap-3">
                                <div className="h-12 w-12 rounded-lg bg-red-100 flex items-center justify-center">
                                    <Trash2 className="h-6 w-6 text-red-600" />
                                </div>
                                <div>
                                    <CardTitle>Old Images Cleanup</CardTitle>
                                    <CardDescription>Runs daily at 2 AM</CardDescription>
                                </div>
                            </div>
                        </div>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="text-sm text-gray-600 space-y-2">
                            <p>This job:</p>
                            <ul className="list-disc list-inside space-y-1 text-gray-500">
                                <li>Finds scan images older than 30 days</li>
                                <li>Deletes them from Supabase storage</li>
                                <li>Frees up storage space</li>
                                <li>Logs cleanup statistics</li>
                            </ul>
                        </div>
                        <Button
                            onClick={() => runCronJob("image-cleanup")}
                            disabled={runningJob !== null}
                            variant="destructive"
                            className="w-full"
                        >
                            {runningJob === "image-cleanup" ? (
                                <>
                                    <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                                    Running...
                                </>
                            ) : (
                                <>
                                    <Play className="h-4 w-4 mr-2" />
                                    Run Now
                                </>
                            )}
                        </Button>
                    </CardContent>
                </Card>
            </div>

            {/* Execution History */}
            <Card>
                <CardHeader>
                    <CardTitle>Execution History</CardTitle>
                    <CardDescription>Recent cron job executions</CardDescription>
                </CardHeader>
                <CardContent>
                    {loading ? (
                        <div className="space-y-4">
                            {[1, 2, 3].map((i) => (
                                <Skeleton key={i} className="h-16 w-full" />
                            ))}
                        </div>
                    ) : displayLogs.length === 0 ? (
                        <div className="text-center py-10 text-gray-500">
                            <AlertCircle className="h-12 w-12 mx-auto text-gray-300 mb-3" />
                            <p>No cron job executions yet</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {displayLogs.map((log) => (
                                <div
                                    key={log.id}
                                    className="flex items-center justify-between p-4 border rounded-lg"
                                >
                                    <div className="flex items-center gap-4">
                                        <div className={`h-10 w-10 rounded-lg flex items-center justify-center ${log.status === "completed" ? "bg-green-100" :
                                                log.status === "failed" ? "bg-red-100" :
                                                    "bg-blue-100"
                                            }`}>
                                            {log.status === "completed" ? (
                                                <CheckCircle className="h-5 w-5 text-green-600" />
                                            ) : log.status === "failed" ? (
                                                <XCircle className="h-5 w-5 text-red-600" />
                                            ) : (
                                                <Loader2 className="h-5 w-5 text-blue-600 animate-spin" />
                                            )}
                                        </div>
                                        <div>
                                            <div className="font-medium text-gray-900 flex items-center gap-2">
                                                {log.jobName === "premium-expiry" ? "Premium Expiry Check" : "Image Cleanup"}
                                                <Badge variant={log.status === "completed" ? "default" : log.status === "failed" ? "destructive" : "secondary"}>
                                                    {log.status}
                                                </Badge>
                                            </div>
                                            <div className="text-sm text-gray-500">
                                                {log.recordsProcessed} records processed
                                                {log.errorMessage && (
                                                    <span className="text-red-500 ml-2">• {log.errorMessage}</span>
                                                )}
                                            </div>
                                        </div>
                                    </div>
                                    <div className="text-right">
                                        <div className="text-sm text-gray-900">
                                            {format(new Date(log.startedAt), "PPp")}
                                        </div>
                                        <div className="text-xs text-gray-500">
                                            {formatDistanceToNow(new Date(log.startedAt), { addSuffix: true })}
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
