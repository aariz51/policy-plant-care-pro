"use client";

import { useEffect, useState } from "react";
import { useAuthStore } from "@/lib/auth-store";
import { adminApi, UserSummary } from "@/lib/api";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import {
    Table,
    TableBody,
    TableCell,
    TableHead,
    TableHeader,
    TableRow,
} from "@/components/ui/table";
import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
} from "@/components/ui/select";
import { Search, Users, ChevronLeft, ChevronRight, Crown, User } from "lucide-react";
import { formatDistanceToNow } from "date-fns";
import Link from "next/link";

export default function UsersPage() {
    const { session } = useAuthStore();
    const [users, setUsers] = useState<UserSummary[]>([]);
    const [loading, setLoading] = useState(true);
    const [search, setSearch] = useState("");
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [total, setTotal] = useState(0);
    const [tierFilter, setTierFilter] = useState<string>("all");

    useEffect(() => {
        async function fetchUsers() {
            if (!session?.access_token) return;

            setLoading(true);
            const result = await adminApi.getUsers(session.access_token, page, 20, search);

            if (result.success && result.data) {
                // Apply client-side tier filtering if needed
                let filteredUsers = result.data.users;
                if (tierFilter !== "all") {
                    filteredUsers = filteredUsers.filter(u => u.membershipTier === tierFilter);
                }
                setUsers(filteredUsers);
                setTotalPages(result.data.totalPages);
                setTotal(result.data.total);
            }
            setLoading(false);
        }

        fetchUsers();
    }, [session, page, search, tierFilter]);

    const handleSearch = (value: string) => {
        setSearch(value);
        setPage(1);
    };

    const getTierBadge = (tier: string) => {
        const tierColors: Record<string, string> = {
            free: "bg-gray-100 text-gray-700",
            premium_weekly: "bg-blue-100 text-blue-700",
            premium_monthly: "bg-purple-100 text-purple-700",
            premium_yearly: "bg-amber-100 text-amber-700",
        };

        const tierLabels: Record<string, string> = {
            free: "Free",
            premium_weekly: "Weekly",
            premium_monthly: "Monthly",
            premium_yearly: "Yearly",
        };

        return (
            <Badge className={tierColors[tier] || "bg-gray-100 text-gray-700"}>
                {tier.includes("premium") && <Crown className="h-3 w-3 mr-1" />}
                {tierLabels[tier] || tier}
            </Badge>
        );
    };

    return (
        <div className="space-y-6">
            {/* Page Header */}
            <div>
                <h1 className="text-3xl font-bold text-gray-900 flex items-center gap-2">
                    <Users className="h-8 w-8 text-purple-600" />
                    Users Management
                </h1>
                <p className="text-gray-500 mt-1">
                    View and manage all SafeMama users
                </p>
            </div>

            {/* Filters */}
            <Card>
                <CardContent className="pt-6">
                    <div className="flex gap-4">
                        <div className="relative flex-1">
                            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                            <Input
                                placeholder="Search by email or name..."
                                value={search}
                                onChange={(e) => handleSearch(e.target.value)}
                                className="pl-10"
                            />
                        </div>
                        <Select value={tierFilter} onValueChange={setTierFilter}>
                            <SelectTrigger className="w-48">
                                <SelectValue placeholder="Filter by tier" />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="all">All Tiers</SelectItem>
                                <SelectItem value="free">Free</SelectItem>
                                <SelectItem value="premium_weekly">Premium Weekly</SelectItem>
                                <SelectItem value="premium_monthly">Premium Monthly</SelectItem>
                                <SelectItem value="premium_yearly">Premium Yearly</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                </CardContent>
            </Card>

            {/* Users Table */}
            <Card>
                <CardHeader>
                    <CardTitle>All Users</CardTitle>
                    <CardDescription>
                        Showing {users.length} of {total} total users
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    {loading ? (
                        <UsersTableSkeleton />
                    ) : users.length === 0 ? (
                        <div className="text-center py-10 text-gray-500">
                            No users found matching your criteria
                        </div>
                    ) : (
                        <>
                            <Table>
                                <TableHeader>
                                    <TableRow>
                                        <TableHead>User</TableHead>
                                        <TableHead>Tier</TableHead>
                                        <TableHead>Scans</TableHead>
                                        <TableHead>Ask Expert</TableHead>
                                        <TableHead>Last Active</TableHead>
                                        <TableHead>Joined</TableHead>
                                        <TableHead></TableHead>
                                    </TableRow>
                                </TableHeader>
                                <TableBody>
                                    {users.map((user) => (
                                        <TableRow key={user.id}>
                                            <TableCell>
                                                <div className="flex items-center gap-3">
                                                    <div className="h-9 w-9 rounded-full bg-gradient-to-br from-pink-100 to-purple-100 flex items-center justify-center">
                                                        <User className="h-5 w-5 text-purple-600" />
                                                    </div>
                                                    <div>
                                                        <div className="font-medium text-gray-900">
                                                            {user.fullName || "Unknown"}
                                                        </div>
                                                        <div className="text-sm text-gray-500">
                                                            {user.email}
                                                        </div>
                                                    </div>
                                                </div>
                                            </TableCell>
                                            <TableCell>{getTierBadge(user.membershipTier)}</TableCell>
                                            <TableCell className="text-gray-600">{user.scanCount}</TableCell>
                                            <TableCell className="text-gray-600">{user.askExpertCount}</TableCell>
                                            <TableCell className="text-gray-500 text-sm">
                                                {user.lastActivity
                                                    ? formatDistanceToNow(new Date(user.lastActivity), { addSuffix: true })
                                                    : "Never"}
                                            </TableCell>
                                            <TableCell className="text-gray-500 text-sm">
                                                {formatDistanceToNow(new Date(user.createdAt), { addSuffix: true })}
                                            </TableCell>
                                            <TableCell>
                                                <Link href={`/users/${user.id}`}>
                                                    <Button variant="ghost" size="sm">
                                                        View
                                                    </Button>
                                                </Link>
                                            </TableCell>
                                        </TableRow>
                                    ))}
                                </TableBody>
                            </Table>

                            {/* Pagination */}
                            <div className="flex items-center justify-between mt-4">
                                <div className="text-sm text-gray-500">
                                    Page {page} of {totalPages}
                                </div>
                                <div className="flex gap-2">
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setPage(p => Math.max(1, p - 1))}
                                        disabled={page === 1}
                                    >
                                        <ChevronLeft className="h-4 w-4" />
                                        Previous
                                    </Button>
                                    <Button
                                        variant="outline"
                                        size="sm"
                                        onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                                        disabled={page === totalPages}
                                    >
                                        Next
                                        <ChevronRight className="h-4 w-4" />
                                    </Button>
                                </div>
                            </div>
                        </>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}

function UsersTableSkeleton() {
    return (
        <div className="space-y-4">
            {[1, 2, 3, 4, 5].map((i) => (
                <div key={i} className="flex items-center gap-4">
                    <Skeleton className="h-9 w-9 rounded-full" />
                    <div className="flex-1">
                        <Skeleton className="h-4 w-32" />
                        <Skeleton className="h-3 w-48 mt-1" />
                    </div>
                    <Skeleton className="h-6 w-16" />
                    <Skeleton className="h-4 w-12" />
                    <Skeleton className="h-4 w-12" />
                    <Skeleton className="h-4 w-24" />
                </div>
            ))}
        </div>
    );
}
