import { create } from "zustand";
import { persist } from "zustand/middleware";
import { supabase } from "./supabase";
import type { User, Session } from "@supabase/supabase-js";

interface AuthState {
    user: User | null;
    session: Session | null;
    isAdmin: boolean;
    isLoading: boolean;
    error: string | null;

    // Actions
    signIn: (email: string, password: string) => Promise<boolean>;
    signOut: () => Promise<void>;
    checkAdminRole: () => Promise<boolean>;
    setSession: (session: Session | null) => void;
    clearError: () => void;
}

export const useAuthStore = create<AuthState>()(
    persist(
        (set, get) => ({
            user: null,
            session: null,
            isAdmin: false,
            isLoading: false,
            error: null,

            signIn: async (email: string, password: string) => {
                if (!supabase) {
                    set({ error: "Supabase not configured" });
                    return false;
                }

                set({ isLoading: true, error: null });

                try {
                    const { data, error } = await supabase.auth.signInWithPassword({
                        email,
                        password,
                    });

                    if (error) {
                        set({ isLoading: false, error: error.message });
                        return false;
                    }

                    if (!data.session || !data.user) {
                        set({ isLoading: false, error: "Login failed" });
                        return false;
                    }

                    set({
                        user: data.user,
                        session: data.session,
                        isLoading: false
                    });

                    // Check if user has admin role
                    const isAdmin = await get().checkAdminRole();

                    if (!isAdmin) {
                        // Sign out if not admin
                        await supabase.auth.signOut();
                        set({
                            user: null,
                            session: null,
                            isAdmin: false,
                            error: "Access denied. Admin role required."
                        });
                        return false;
                    }

                    return true;
                } catch (err) {
                    set({
                        isLoading: false,
                        error: err instanceof Error ? err.message : "Login failed"
                    });
                    return false;
                }
            },

            signOut: async () => {
                if (supabase) {
                    await supabase.auth.signOut();
                }
                set({
                    user: null,
                    session: null,
                    isAdmin: false,
                    error: null
                });
            },

            checkAdminRole: async () => {
                if (!supabase) return false;

                const { user } = get();
                if (!user) return false;

                try {
                    const { data, error } = await supabase
                        .from("profiles")
                        .select("role")
                        .eq("id", user.id)
                        .single();

                    if (error || !data) {
                        set({ isAdmin: false });
                        return false;
                    }

                    const isAdmin = data.role?.toLowerCase() === "admin";
                    set({ isAdmin });
                    return isAdmin;
                } catch {
                    set({ isAdmin: false });
                    return false;
                }
            },

            setSession: (session: Session | null) => {
                set({
                    session,
                    user: session?.user ?? null
                });
            },

            clearError: () => set({ error: null }),
        }),
        {
            name: "safemama-admin-auth",
            partialize: (state) => ({
                // Only persist session data
                session: state.session,
                user: state.user,
                isAdmin: state.isAdmin,
            }),
        }
    )
);

// Initialize auth state on app load
export async function initializeAuth() {
    if (!supabase) return;

    const { data: { session } } = await supabase.auth.getSession();

    if (session) {
        useAuthStore.getState().setSession(session);
        await useAuthStore.getState().checkAdminRole();
    }

    // Listen for auth changes
    supabase.auth.onAuthStateChange((_event, session) => {
        useAuthStore.getState().setSession(session);
        if (session) {
            useAuthStore.getState().checkAdminRole();
        }
    });
}
