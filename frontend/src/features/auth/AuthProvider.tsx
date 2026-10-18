import { useEffect, useState, type ReactNode } from "react";
import {
  apiRequest,
  clearToken,
  loginRequest,
  logoutRequest,
  signupRequest,
} from "../../lib/api";
import { AuthContext, type AuthUser } from "./AuthContext";

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(
    () => Boolean(sessionStorage.getItem("procure-pulse-token")),
  );

  useEffect(() => {
    if (!sessionStorage.getItem("procure-pulse-token")) {
      return;
    }

    apiRequest<AuthUser>("/me")
      .then(setUser)
      .catch(() => {
        clearToken();
        setUser(null);
      })
      .finally(() => setLoading(false));
  }, []);

  async function login(email: string, password: string) {
    const result = await loginRequest(email, password);
    setUser(result.user);
  }

  async function signup(
    email: string,
    password: string,
    passwordConfirmation: string,
  ) {
    await signupRequest(email, password, passwordConfirmation);
    await login(email, password);
  }

  async function logout() {
    try {
      await logoutRequest();
    } finally {
      setUser(null);
    }
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, signup, logout }}>
      {children}
    </AuthContext.Provider>
  );
}
