import { useEffect, useState, type ReactNode } from "react";
import {
  apiRequest,
  clearToken,
  getToken,
  loginRequest,
  logoutRequest,
  signupRequest,
} from "../../lib/api";
import { AuthContext, type AuthUser } from "./AuthContext";

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [loading, setLoading] = useState(() => Boolean(getToken()));

  
  useEffect(() => {
    if (!getToken()) return;

    let active = true;

    apiRequest<{ user: AuthUser }>("/me")
      .then((result) => {
        if (active) setUser(result.user);
      })
      .catch(() => {
        if (active) {
          clearToken();
          setUser(null);
        }
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
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
