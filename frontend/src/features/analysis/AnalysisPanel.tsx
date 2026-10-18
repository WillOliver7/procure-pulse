import type { AnalysisRun } from "./analysis.types";

type AnalysisPanelProps = {
  analysis: AnalysisRun;
};

function AnalysisPanel({ analysis }: AnalysisPanelProps) {
  const results = analysis.results;

  return (
    <section className="panel">
      <h2>Analysis #{analysis.id}</h2>
      <p>
        Status: <strong>{analysis.status}</strong>
      </p>

      {analysis.status === "pending" && <p>Waiting for a worker...</p>}
      {analysis.status === "processing" && <p>Calculating spending...</p>}

      {analysis.status === "failed" && (
        <p className="error">
          {analysis.error_message || "Analysis failed."}
        </p>
      )}

      {analysis.status === "completed" && results && (
        <>
          <div className="metric">
            <span>Total spend</span>
            <strong>
              {results.currency} {results.total_spend_usd}
            </strong>
          </div>

          <p>Purchase orders: {results.order_count}</p>

          <h3>Spending by supplier</h3>
          <ul>
            {results.spend_by_supplier?.map((supplier) => (
              <li key={supplier.name}>
                {supplier.name} — ${supplier.spend_usd}
              </li>
            ))}
          </ul>

          <h3>Spending by category</h3>
          <ul>
            {results.spend_by_category?.map((category) => (
              <li key={category.name}>
                {category.name} — ${category.spend_usd}
              </li>
            ))}
          </ul>
        </>
      )}
    </section>
  );
}

export default AnalysisPanel;
