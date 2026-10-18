import { useState, type FormEvent } from "react";
import { useAuth } from "./useAuth";

function AuthForm() {
  const { login, signup } = useAuth();
  const [mode, setMode] = useState<"login" | "signup">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError("");
    setSubmitting(true);

    try {
      if (mode === "signup") {
        if (password !== passwordConfirmation) {
          throw new Error("Passwords do not match.");
        }

        await signup(email, password, passwordConfirmation);
      } else {
        await login(email, password);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Something went wrong.");
    } finally {
      setSubmitting(false);
    }
  }

  function changeMode() {
    setMode((current) => (current === "login" ? "signup" : "login"));
    setError("");
  }

  return (
    <section className="panel auth-card">
      <h2>{mode === "login" ? "Welcome back" : "Create your account"}</h2>
      <p>
        {mode === "login"
          ? "Sign in to access your procurement analytics."
          : "Create an account to get started."}
      </p>

      <form className="auth-form" onSubmit={handleSubmit}>
        <label htmlFor="email">Email</label>
        <input
          id="email"
          type="email"
          autoComplete="email"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          required
        />

        <label htmlFor="password">Password</label>
        <input
          id="password"
          type="password"
          autoComplete={mode === "login" ? "current-password" : "new-password"}
          value={password}
          onChange={(event) => setPassword(event.target.value)}
          required
        />

        {mode === "signup" && (
          <>
            <label htmlFor="password-confirmation">Confirm password</label>
            <input
              id="password-confirmation"
              type="password"
              autoComplete="new-password"
              value={passwordConfirmation}
              onChange={(event) => setPasswordConfirmation(event.target.value)}
              required
            />
          </>
        )}

        {error && <p className="error">{error}</p>}

        <button type="submit" disabled={submitting}>
          {submitting
            ? "Please wait..."
            : mode === "login"
              ? "Sign in"
              : "Create account"}
        </button>
      </form>

      <p>
        {mode === "login" ? "Don't have an account?" : "Already registered?"}{" "}
        <button className="text-button" type="button" onClick={changeMode}>
          {mode === "login" ? "Sign up" : "Sign in"}
        </button>
      </p>
    </section>
  );
}

export default AuthForm;
