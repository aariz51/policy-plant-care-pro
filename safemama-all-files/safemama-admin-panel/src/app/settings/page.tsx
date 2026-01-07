"use client";

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Settings, ExternalLink, Database, Server, Globe } from "lucide-react";

export default function SettingsPage() {
    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div>
                <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                    <Settings className="h-8 w-8 text-purple-600" />
                    Settings
                </h1>
                <p className="text-gray-500 mt-1">
                    Admin panel configuration and quick links
                </p>
            </div>

            <div className="grid gap-6 md:grid-cols-2">
                {/* Quick Links */}
                <Card>
                    <CardHeader>
                        <CardTitle>Quick Links</CardTitle>
                        <CardDescription>External service dashboards</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-3">
                        <Button variant="outline" className="w-full justify-start gap-3" asChild>
                            <a href="https://supabase.com/dashboard" target="_blank" rel="noopener noreferrer">
                                <Database className="h-4 w-4" />
                                Supabase Dashboard
                                <ExternalLink className="h-3 w-3 ml-auto" />
                            </a>
                        </Button>
                        <Button variant="outline" className="w-full justify-start gap-3" asChild>
                            <a href="https://app.revenuecat.com" target="_blank" rel="noopener noreferrer">
                                <Server className="h-4 w-4" />
                                RevenueCat Dashboard
                                <ExternalLink className="h-3 w-3 ml-auto" />
                            </a>
                        </Button>
                        <Button variant="outline" className="w-full justify-start gap-3" asChild>
                            <a href="https://console.firebase.google.com" target="_blank" rel="noopener noreferrer">
                                <Globe className="h-4 w-4" />
                                Firebase Console
                                <ExternalLink className="h-3 w-3 ml-auto" />
                            </a>
                        </Button>
                    </CardContent>
                </Card>

                {/* Environment Info */}
                <Card>
                    <CardHeader>
                        <CardTitle>Environment</CardTitle>
                        <CardDescription>Current configuration</CardDescription>
                    </CardHeader>
                    <CardContent className="space-y-4">
                        <div className="flex justify-between text-sm">
                            <span className="text-gray-500">API URL</span>
                            <code className="bg-gray-100 px-2 py-1 rounded text-xs">
                                {process.env.NEXT_PUBLIC_API_URL || "Not configured"}
                            </code>
                        </div>
                        <div className="flex justify-between text-sm">
                            <span className="text-gray-500">Supabase</span>
                            <code className="bg-gray-100 px-2 py-1 rounded text-xs">
                                {process.env.NEXT_PUBLIC_SUPABASE_URL ? "Connected" : "Not configured"}
                            </code>
                        </div>
                    </CardContent>
                </Card>

                {/* Pricing Configuration */}
                <Card className="md:col-span-2">
                    <CardHeader>
                        <CardTitle>Pricing Configuration (USD)</CardTitle>
                        <CardDescription>Current subscription pricing for MRR calculations</CardDescription>
                    </CardHeader>
                    <CardContent>
                        <div className="grid gap-4 md:grid-cols-3">
                            <div className="p-4 border rounded-lg">
                                <div className="text-sm text-gray-500">Weekly Plan</div>
                                <div className="text-2xl font-bold text-gray-900">$2.49</div>
                                <div className="text-xs text-gray-400 mt-1">~$10.77/month (×4.33)</div>
                            </div>
                            <div className="p-4 border rounded-lg">
                                <div className="text-sm text-gray-500">Monthly Plan</div>
                                <div className="text-2xl font-bold text-gray-900">$3.99</div>
                                <div className="text-xs text-gray-400 mt-1">Direct MRR</div>
                            </div>
                            <div className="p-4 border rounded-lg">
                                <div className="text-sm text-gray-500">Yearly Plan</div>
                                <div className="text-2xl font-bold text-gray-900">$39.99</div>
                                <div className="text-xs text-gray-400 mt-1">$3.33/month (÷12)</div>
                            </div>
                        </div>
                    </CardContent>
                </Card>
            </div>
        </div>
    );
}
