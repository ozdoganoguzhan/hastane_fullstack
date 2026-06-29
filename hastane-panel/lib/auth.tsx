"use client";

import * as React from "react";

import { api, tokenStore } from "./api";
import type { AuthUser } from "./types";

interface AuthContextValue {
  user: AuthUser | null;
  isAuthenticated: boolean;
  ready: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = React.createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = React.useState<AuthUser | null>(null);
  const [token, setToken] = React.useState<string | null>(null);
  const [ready, setReady] = React.useState(false);

  React.useEffect(() => {
    setToken(tokenStore.get());
    setUser(tokenStore.getUser());
    setReady(true);
  }, []);

  const login = React.useCallback(async (username: string, password: string) => {
    const res = await api.login(username, password);
    tokenStore.set(res.token, res.user);
    setToken(res.token);
    setUser(res.user);
  }, []);

  const logout = React.useCallback(() => {
    tokenStore.clear();
    setToken(null);
    setUser(null);
  }, []);

  const value = React.useMemo<AuthContextValue>(
    () => ({ user, isAuthenticated: Boolean(token), ready, login, logout }),
    [user, token, ready, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = React.useContext(AuthContext);

  if (!ctx) throw new Error("useAuth, AuthProvider içinde kullanılmalıdır.");

  return ctx;
}
