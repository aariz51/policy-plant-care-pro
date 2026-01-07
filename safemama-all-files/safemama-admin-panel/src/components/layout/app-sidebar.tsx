"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import {
    LayoutDashboard,
    Users,
    BarChart3,
    DollarSign,
    Activity,
    Settings,
    Clock,
    LogOut,
    Baby,
} from "lucide-react";
import { useAuthStore } from "@/lib/auth-store";
import { Button } from "@/components/ui/button";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Separator } from "@/components/ui/separator";

const navItems = [
    {
        title: "Dashboard",
        href: "/",
        icon: LayoutDashboard,
    },
    {
        title: "Users",
        href: "/users",
        icon: Users,
    },
    {
        title: "Analytics",
        href: "/analytics",
        icon: BarChart3,
    },
    {
        title: "Revenue",
        href: "/revenue",
        icon: DollarSign,
    },
    {
        title: "Activity",
        href: "/activity",
        icon: Activity,
    },
    {
        title: "Cron Jobs",
        href: "/cron-jobs",
        icon: Clock,
    },
    {
        title: "Settings",
        href: "/settings",
        icon: Settings,
    },
];

export function AppSidebar() {
    const pathname = usePathname();
    const { user, signOut } = useAuthStore();

    const handleSignOut = async () => {
        await signOut();
        window.location.href = "/login";
    };

    return (
        <div className="flex h-screen w-64 flex-col border-r bg-white">
            {/* Logo */}
            <div className="flex h-16 items-center gap-2 px-6 border-b">
                <div className="h-8 w-8 rounded-lg bg-gradient-to-br from-pink-500 to-purple-600 flex items-center justify-center">
                    <Baby className="h-5 w-5 text-white" />
                </div>
                <span className="text-lg font-bold bg-gradient-to-r from-pink-600 to-purple-600 bg-clip-text text-transparent">
                    SafeMama Admin
                </span>
            </div>

            {/* Navigation */}
            <nav className="flex-1 space-y-1 px-3 py-4">
                {navItems.map((item) => {
                    const isActive = pathname === item.href;
                    return (
                        <Link
                            key={item.href}
                            href={item.href}
                            className={cn(
                                "flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors",
                                isActive
                                    ? "bg-gradient-to-r from-pink-50 to-purple-50 text-purple-700"
                                    : "text-gray-600 hover:bg-gray-50 hover:text-gray-900"
                            )}
                        >
                            <item.icon
                                className={cn(
                                    "h-5 w-5",
                                    isActive ? "text-purple-600" : "text-gray-400"
                                )}
                            />
                            {item.title}
                        </Link>
                    );
                })}
            </nav>

            <Separator />

            {/* User section */}
            <div className="p-4">
                <div className="flex items-center gap-3 mb-3">
                    <Avatar className="h-9 w-9">
                        <AvatarFallback className="bg-gradient-to-br from-pink-500 to-purple-600 text-white text-sm">
                            {user?.email?.charAt(0).toUpperCase() || "A"}
                        </AvatarFallback>
                    </Avatar>
                    <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 truncate">
                            {user?.email || "Admin"}
                        </p>
                        <p className="text-xs text-gray-500">Administrator</p>
                    </div>
                </div>
                <Button
                    variant="outline"
                    size="sm"
                    className="w-full justify-start gap-2 text-gray-600"
                    onClick={handleSignOut}
                >
                    <LogOut className="h-4 w-4" />
                    Sign Out
                </Button>
            </div>
        </div>
    );
}
