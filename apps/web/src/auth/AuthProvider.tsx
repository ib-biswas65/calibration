import { createContext, useCallback, useEffect, useMemo, useState, type ReactNode } from "react";

import { apiFetch, ApiError } from "../api/client";
import type { AuthMe } from "../api/types";

interface AuthContextValue {
  user: AuthMe | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  refresh: () => Promise<void>;
}

export const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthMe | null>(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    try {
      const me = await apiFetch<AuthMe>("/api/auth/me");
      setUser(me);
    } catch (e) {
      if (e instanceof ApiError && e.status === 401) setUser(null);
      else throw e;
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh().catch(() => setLoading(false));
  }, [refresh]);

  const login = useCallback(async (email: string, password: string) => {
    await apiFetch<void>("/api/auth/login", {
      method: "POST",
      json: { email, password },
    });
    await refresh();
  }, [refresh]);

  const logout = useCallback(async () => {
    await apiFetch<void>("/api/auth/logout", { method: "POST" });
    setUser(null);
  }, []);

  const value = useMemo(
    () => ({ user, loading, login, logout, refresh }),
    [user, loading, login, logout, refresh],
  );
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}
