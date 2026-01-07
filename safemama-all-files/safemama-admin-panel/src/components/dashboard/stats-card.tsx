"use client";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { LucideIcon } from "lucide-react";

interface StatsCardProps {
    title: string;
    value: string | number;
    description?: string;
    icon: LucideIcon;
    trend?: {
        value: number;
        isPositive: boolean;
    };
    className?: string;
    iconClassName?: string;
}

export function StatsCard({
    title,
    value,
    description,
    icon: Icon,
    trend,
    className,
    iconClassName,
}: StatsCardProps) {
    return (
        <Card className={cn("transition-shadow hover:shadow-lg", className)}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
                <CardTitle className="text-sm font-medium text-gray-500">
                    {title}
                </CardTitle>
                <div className={cn(
                    "h-9 w-9 rounded-lg flex items-center justify-center",
                    iconClassName || "bg-gradient-to-br from-pink-100 to-purple-100"
                )}>
                    <Icon className={cn("h-5 w-5", iconClassName ? "text-white" : "text-purple-600")} />
                </div>
            </CardHeader>
            <CardContent>
                <div className="text-2xl font-bold text-gray-900">{value}</div>
                {(description || trend) && (
                    <div className="flex items-center gap-2 mt-1">
                        {trend && (
                            <span
                                className={cn(
                                    "text-xs font-medium",
                                    trend.isPositive ? "text-green-600" : "text-red-600"
                                )}
                            >
                                {trend.isPositive ? "+" : ""}
                                {trend.value}%
                            </span>
                        )}
                        {description && (
                            <span className="text-xs text-gray-500">{description}</span>
                        )}
                    </div>
                )}
            </CardContent>
        </Card>
    );
}
