const API_URL =
  import.meta.env.VITE_API_URL ?? "http://localhost:3000/api/v1";

const TOKEN_KEY = "procure-pulse-token";

type ApiError = {
  error?: string;
  errors?: string[];
  message?: string;
};

export function getToken(): string | null {
  return sessionStorage.getItem(TOKEN_KEY);
}

export function saveToken(token: string): void {
  sessionStorage.setItem(TOKEN_KEY, token);
}

export function clearToken(): void {
  sessionStorage.removeItem(TOKEN_KEY);
}

async function parseResponse<T>(response: Response): Promise<T> {
  const text = await response.text();

  let data: unknown = null;

  if (text.trim()) {
    try {
      data = JSON.parse(text);
    } catch {
      if (response.ok) {
        throw new Error("The server returned an invalid JSON response.");
      }
    }
  }

  if (!response.ok) {
    const body = data as ApiError | null;

    const message =
      body?.error ??
      body?.message ??
      (Array.isArray(body?.errors) ? body.errors.join(", ") : null) ??
      `Request failed (${response.status} ${response.statusText})`;

    throw new Error(message);
  }

  return data as T;
}

export async function apiRequest<T>(
  path: string,
  options: RequestInit = {},
): Promise<T> {
  const headers = new Headers(options.headers);
  const token = getToken();

  if (options.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  if (token) {
    headers.set("Authorization", token);
  }

  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers,
  });

  return parseResponse<T>(response);
}

type AuthResponse = {
  user: {
    id: number;
    email: string;
  };
};

export async function loginRequest(
  email: string,
  password: string,
): Promise<AuthResponse> {
  const response = await fetch(`${API_URL}/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ user: { email, password } }),
  });

  const result = await parseResponse<AuthResponse>(response);
  const token = response.headers.get("Authorization");

  if (!token) {
    throw new Error("Login succeeded, but the server did not return a JWT.");
  }

  saveToken(token);
  return result;
}

export async function signupRequest(
  email: string,
  password: string,
  passwordConfirmation: string,
): Promise<AuthResponse> {
  return apiRequest<AuthResponse>("/signup", {
    method: "POST",
    body: JSON.stringify({
      user: {
        email,
        password,
        password_confirmation: passwordConfirmation,
      },
    }),
  });
}

export async function logoutRequest(): Promise<void> {
  try {
    await apiRequest<void>("/logout", { method: "DELETE" });
  } finally {
    clearToken();
  }
}
