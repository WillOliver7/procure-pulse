import { useEffect, useState } from "react";
import { createConsumer } from "@rails/actioncable";
import AppHeader from "./components/layout/AppHeader";
import AnalysisPanel from "./features/analysis/AnalysisPanel";
import type { AnalysisRun } from "./features/analysis/analysis.types";
import AuthForm from "./features/auth/AuthForm";
import { AuthProvider } from "./features/auth/AuthProvider";
import { useAuth } from "./features/auth/useAuth";
import { apiRequest } from "./lib/api";
import "./App.css";

const CABLE_URL =
  import.meta.env.VITE_CABLE_URL ??
  `${window.location.protocol === "https:" ? "wss:" : "ws:"}//${window.location.host}/cable`;

function Dashboard() {
  const { user, logout } = useAuth();
  const [analysis, setAnalysis] = useState<AnalysisRun | null>(null);
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (!analysis?.id) return;

    const consumer = createConsumer(CABLE_URL);
    const subscription = consumer.subscriptions.create(
      { channel: "AnalysisRunChannel", id: analysis.id },
      {
        received(data: AnalysisRun) {
          setAnalysis(data);
        },
      },
    );

    apiRequest<AnalysisRun>(`/analysis_runs/${analysis.id}`)
      .then(setAnalysis)
      .catch((err: Error) => setError(err.message));

    return () => {
      subscription.unsubscribe();
      consumer.disconnect();
    };
  }, [analysis?.id]);

  async function startAnalysis() {
    setStarting(true);
    setError("");
    setAnalysis(null);

    try {
      const data = await apiRequest<AnalysisRun>("/analysis_runs", {
        method: "POST",
      });
      setAnalysis(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not start analysis.");
    } finally {
      setStarting(false);
    }
  }

  async function handleLogout() {
    try {
      await logout();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Logout failed.");
    }
  }

  return (
    <main className="dashboard">
      <div className="dashboard-top">
        <AppHeader />
        <div className="user-controls">
          <span>{user?.email}</span>
          <button className="secondary-button" onClick={handleLogout}>
            Sign out
          </button>
        </div>
      </div>

      <button onClick={startAnalysis} disabled={starting}>
        {starting ? "Starting..." : "Run procurement analysis"}
      </button>

      {error && <p className="error">{error}</p>}
      {analysis && <AnalysisPanel analysis={analysis} />}
    </main>
  );
}

function AppContent() {
  const { user, loading } = useAuth();

  if (loading) {
    return <main className="dashboard">Checking your session...</main>;
  }

  return user ? <Dashboard /> : (
    <main className="dashboard">
      <AppHeader />
      <AuthForm />
    </main>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
