"use client";

import { useEffect, useState } from "react";
import { useAuthStore } from "@/lib/auth-store";
import { StatsCard } from "@/components/dashboard/stats-card";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Users,
  Crown,
  DollarSign,
  TrendingUp,
  Scan,
  MessageSquare,
  BookOpen,
  FileText,
  Activity,
  Baby
} from "lucide-react";
import { formatCurrency, formatNumber, calculateMRR } from "@/lib/revenue";
import { adminApi, DashboardStats } from "@/lib/api";

export default function DashboardPage() {
  const { session } = useAuthStore();
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchStats() {
      if (!session?.access_token) return;

      setLoading(true);
      const result = await adminApi.getDashboardStats(session.access_token);

      if (result.success && result.data) {
        setStats(result.data);
      } else {
        setError(result.error || "Failed to load dashboard stats");
      }
      setLoading(false);
    }

    fetchStats();
  }, [session]);

  if (loading) {
    return <DashboardSkeleton />;
  }

  if (error) {
    return (
      <div className="text-center py-10">
        <p className="text-red-500 mb-2">{error}</p>
        <p className="text-gray-500 text-sm">
          Make sure the backend is running and admin endpoints are configured.
        </p>
      </div>
    );
  }

  // If no stats from API yet, show placeholder data
  const displayStats = stats || {
    totalUsers: 0,
    premiumUsers: { weekly: 0, monthly: 0, yearly: 0, total: 0 },
    mrr: 0,
    totalRevenue: 0,
    featureUsage: {
      totalScans: 0,
      totalAskExpert: 0,
      totalGuides: 0,
      totalDocumentAnalysis: 0,
      totalPregnancyTests: 0,
    },
    todayStats: { newUsers: 0, newPremium: 0, scansToday: 0 },
  };

  const calculatedMRR = displayStats.mrr || calculateMRR(displayStats.premiumUsers);

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500 mt-1">
          Welcome back! Here&apos;s an overview of SafeMama today.
        </p>
      </div>

      {/* Main Stats Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <StatsCard
          title="Total Users"
          value={formatNumber(displayStats.totalUsers)}
          description="All registered users"
          icon={Users}
          trend={displayStats.todayStats.newUsers > 0 ? {
            value: displayStats.todayStats.newUsers,
            isPositive: true
          } : undefined}
        />
        <StatsCard
          title="Premium Members"
          value={formatNumber(displayStats.premiumUsers.total)}
          description={`${displayStats.premiumUsers.weekly}W / ${displayStats.premiumUsers.monthly}M / ${displayStats.premiumUsers.yearly}Y`}
          icon={Crown}
          iconClassName="bg-gradient-to-br from-amber-400 to-orange-500"
        />
        <StatsCard
          title="MRR"
          value={formatCurrency(calculatedMRR)}
          description="Monthly Recurring Revenue"
          icon={DollarSign}
          iconClassName="bg-gradient-to-br from-green-400 to-emerald-500"
        />
        <StatsCard
          title="Total Revenue"
          value={formatCurrency(displayStats.totalRevenue)}
          description="All-time revenue"
          icon={TrendingUp}
          iconClassName="bg-gradient-to-br from-blue-400 to-indigo-500"
        />
      </div>

      {/* Premium Breakdown */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Crown className="h-5 w-5 text-amber-500" />
            Premium Subscribers Breakdown
          </CardTitle>
          <CardDescription>
            Revenue calculation: Weekly $2.49, Monthly $3.99, Yearly $39.99
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-3">
            <div className="p-4 bg-gradient-to-br from-blue-50 to-indigo-50 rounded-lg">
              <div className="text-sm font-medium text-blue-600">Weekly</div>
              <div className="text-2xl font-bold text-gray-900 mt-1">
                {displayStats.premiumUsers.weekly}
              </div>
              <div className="text-sm text-gray-500 mt-1">
                {formatCurrency(displayStats.premiumUsers.weekly * 2.49 * 4.33)}/mo
              </div>
            </div>
            <div className="p-4 bg-gradient-to-br from-pink-50 to-purple-50 rounded-lg">
              <div className="text-sm font-medium text-purple-600">Monthly</div>
              <div className="text-2xl font-bold text-gray-900 mt-1">
                {displayStats.premiumUsers.monthly}
              </div>
              <div className="text-sm text-gray-500 mt-1">
                {formatCurrency(displayStats.premiumUsers.monthly * 3.99)}/mo
              </div>
            </div>
            <div className="p-4 bg-gradient-to-br from-amber-50 to-orange-50 rounded-lg">
              <div className="text-sm font-medium text-orange-600">Yearly</div>
              <div className="text-2xl font-bold text-gray-900 mt-1">
                {displayStats.premiumUsers.yearly}
              </div>
              <div className="text-sm text-gray-500 mt-1">
                {formatCurrency(displayStats.premiumUsers.yearly * (39.99 / 12))}/mo
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Feature Usage */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5 text-purple-500" />
            Feature Usage (All Time)
          </CardTitle>
          <CardDescription>
            Total usage across all features
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-5">
            <FeatureUsageItem
              icon={Scan}
              label="Product Scans"
              value={displayStats.featureUsage.totalScans}
              color="pink"
            />
            <FeatureUsageItem
              icon={MessageSquare}
              label="Ask Expert"
              value={displayStats.featureUsage.totalAskExpert}
              color="blue"
            />
            <FeatureUsageItem
              icon={BookOpen}
              label="Health Guides"
              value={displayStats.featureUsage.totalGuides}
              color="green"
            />
            <FeatureUsageItem
              icon={FileText}
              label="Doc Analysis"
              value={displayStats.featureUsage.totalDocumentAnalysis}
              color="purple"
            />
            <FeatureUsageItem
              icon={Baby}
              label="Pregnancy Tests"
              value={displayStats.featureUsage.totalPregnancyTests}
              color="amber"
            />
          </div>
        </CardContent>
      </Card>

      {/* Today's Activity */}
      <Card>
        <CardHeader>
          <CardTitle>Today&apos;s Activity</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex gap-6">
            <div className="flex items-center gap-3">
              <Badge variant="outline" className="h-10 w-10 rounded-full flex items-center justify-center bg-green-50">
                <Users className="h-5 w-5 text-green-600" />
              </Badge>
              <div>
                <div className="text-2xl font-bold">{displayStats.todayStats.newUsers}</div>
                <div className="text-sm text-gray-500">New Users</div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Badge variant="outline" className="h-10 w-10 rounded-full flex items-center justify-center bg-amber-50">
                <Crown className="h-5 w-5 text-amber-600" />
              </Badge>
              <div>
                <div className="text-2xl font-bold">{displayStats.todayStats.newPremium}</div>
                <div className="text-sm text-gray-500">New Premium</div>
              </div>
            </div>
            <div className="flex items-center gap-3">
              <Badge variant="outline" className="h-10 w-10 rounded-full flex items-center justify-center bg-pink-50">
                <Scan className="h-5 w-5 text-pink-600" />
              </Badge>
              <div>
                <div className="text-2xl font-bold">{displayStats.todayStats.scansToday}</div>
                <div className="text-sm text-gray-500">Scans Today</div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function FeatureUsageItem({
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
  };

  return (
    <div className="flex items-center gap-3 p-3 rounded-lg border">
      <div className={`h-10 w-10 rounded-lg flex items-center justify-center ${colorClasses[color]}`}>
        <Icon className="h-5 w-5" />
      </div>
      <div>
        <div className="text-xl font-bold">{formatNumber(value)}</div>
        <div className="text-xs text-gray-500">{label}</div>
      </div>
    </div>
  );
}

function DashboardSkeleton() {
  return (
    <div className="space-y-6">
      <div>
        <Skeleton className="h-9 w-40" />
        <Skeleton className="h-5 w-60 mt-2" />
      </div>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {[1, 2, 3, 4].map((i) => (
          <Card key={i}>
            <CardHeader className="pb-2">
              <Skeleton className="h-4 w-24" />
            </CardHeader>
            <CardContent>
              <Skeleton className="h-8 w-20" />
              <Skeleton className="h-4 w-32 mt-2" />
            </CardContent>
          </Card>
        ))}
      </div>
      <Card>
        <CardHeader>
          <Skeleton className="h-6 w-48" />
        </CardHeader>
        <CardContent>
          <div className="grid gap-4 md:grid-cols-3">
            {[1, 2, 3].map((i) => (
              <Skeleton key={i} className="h-24 w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
