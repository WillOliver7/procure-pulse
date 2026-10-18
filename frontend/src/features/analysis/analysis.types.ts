export type AnalysisStatus =
  | "pending"
  | "processing"
  | "completed"
  | "failed";

export type SupplierSpend = {
  name: string;
  spend_usd: string;
};

export type CategorySpend = {
  name: string;
  spend_usd: string;
};

export type AnalysisResults = {
  currency?: string;
  order_count?: number;
  total_spend_usd?: string;
  spend_by_supplier?: SupplierSpend[];
  spend_by_category?: CategorySpend[];
};

export type AnalysisRun = {
  id: number;
  status: AnalysisStatus;
  results?: AnalysisResults;
  error_message?: string | null;
};
