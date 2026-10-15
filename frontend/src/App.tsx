import { useEffect, useState } from "react";
import { createConsumer } from "@rails/actioncable";
import "./App.css";

const API_URL = "http://localhost:3000/api/v1";
const CABLE_URL = "ws://localhost:3000/cable";

type AnalysisRun = {
  id: number;
  status: "pending" | "processing" | "completed" | "failed";
  results?: {
    currency?: string;
    order_count?: number;
    total_spend_usd?: string;
    spend_by_supplier?: { name: string; spend_usd: string }[];
    spend_by_category?: { name: string; spend_usd: string }[];
  };
  error_message?: string | null;
};

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

    // Fetch the persisted state too, in case the job finished
    // before the WebSocket subscription was established.
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
      <header>
        <p className="eyebrow">PROCUREMENT INTELLIGENCE</p>
        <h1>ProcurePulse</h1>
        <p>Understand supplier spending and identify opportunities.</p>
      </header>

      <button onClick={startAnalysis} disabled={starting}>
        {starting ? "Starting..." : "Run procurement analysis"}
      </button>

      {error && <p className="error">{error}</p>}

      {analysis && (
        <section className="panel">
          <h2>Analysis #{analysis.id}</h2>
          <p>
            Status: <strong>{analysis.status}</strong>
          </p>

          {analysis.status === "pending" && <p>Waiting for a worker...</p>}
          {analysis.status === "processing" && <p>Calculating spending...</p>}
          {analysis.status === "failed" && (
            <p className="error">{analysis.error_message || "Analysis failed."}</p>
          )}

          {analysis.status === "completed" && analysis.results && (
            <>
              <div className="metric">
                <span>Total spend</span>
                <strong>
                  {analysis.results.currency}{" "}
                  {analysis.results.total_spend_usd}
                </strong>
              </div>

              <p>Purchase orders: {analysis.results.order_count}</p>

              <h3>Spending by supplier</h3>
              <ul>
                {analysis.results.spend_by_supplier?.map((supplier) => (
                  <li key={supplier.name}>
                    {supplier.name} — ${supplier.spend_usd}
                  </li>
                ))}
              </ul>

              <h3>Spending by category</h3>
              <ul>
                {analysis.results.spend_by_category?.map((category) => (
                  <li key={category.name}>
                    {category.name} — ${category.spend_usd}
                  </li>
                ))}
              </ul>
            </>
          )}
        </section>
      )}
    </main>
  );
}

export default App;
