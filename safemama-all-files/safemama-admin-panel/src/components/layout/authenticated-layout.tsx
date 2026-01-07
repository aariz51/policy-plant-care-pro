"use client";

import { useEffect, useState } from "react";
import { useRouter, usePathname } from "next/navigation";
import { useAuthStore, initializeAuth } from "@/lib/auth-store";
import { AppSidebar } from "@/components/layout/app-sidebar";
import { Loader2 } from "lucide-react";

export function AuthenticatedLayout({ children }: { children: React.ReactNode }) {
    const router = useRouter();
    const pathname = usePathname();
    const { session, isAdmin, isLoading } = useAuthStore();
    const [initialized, setInitialized] = useState(false);

    useEffect(() => {
        initializeAuth().then(() => setInitialized(true));
    }, []);

    useEffect(() => {
        if (initialized && !isLoading) {
            if (!session || !isAdmin) {
                router.push("/login");
            }
        }
    }, [initialized, isLoading, session, isAdmin, router]);

    // Skip auth check for login page
    if (pathname === "/login") {
        return <>{children}</>;
    }

    if (!initialized || isLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-pink-50 to-purple-50">
                <div className="text-center">
                    <Loader2 className="h-10 w-10 animate-spin text-pink-500 mx-auto mb-4" />
                    <p className="text-gray-600">Loading admin panel...</p>
                </div>
            </div>
        );
    }

    if (!session || !isAdmin) {
        return null; // Will redirect in useEffect
    }

    return (
        <div className="flex h-screen bg-gray-50">
            <AppSidebar />
            <main className="flex-1 overflow-auto">
                <div className="p-6">{children}</div>
            </main>
        </div>
    );
}
