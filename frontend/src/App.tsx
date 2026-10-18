import { useEffect, useState } from "react";
import { createConsumer } from "@rails/actioncable";
import AppHeader from "./components/layout/AppHeader";
import AnalysisPanel from "./features/analysis/AnalysisPanel";
import type { AnalysisRun } from "./features/analysis/analysis.types";
import "./App.css";

const API_URL = "http://localhost:3000/api/v1";
const CABLE_URL = "ws://localhost:3000/cable";

function App() {
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
      }
    );

    fetch(`${API_URL}/analysis_runs/${analysis.id}`)
      .then((response) => {
        if (!response.ok) throw new Error("Could not fetch analysis");
        return response.json();
      })
      .then((data: AnalysisRun) => setAnalysis(data))
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
      const response = await fetch(`${API_URL}/analysis_runs`, {
        method: "POST",
      });

      if (!response.ok) throw new Error("Could not start analysis");

      const data: AnalysisRun = await response.json();
      setAnalysis(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unexpected error");
    } finally {
      setStarting(false);
    }
  }

  return (
    <main className="dashboard">
      <AppHeader />

      <button onClick={startAnalysis} disabled={starting}>
        {starting ? "Starting..." : "Run procurement analysis"}
      </button>

      {error && <p className="error">{error}</p>}

      {analysis && <AnalysisPanel analysis={analysis} />}
    </main>
  );
}

export default App;
