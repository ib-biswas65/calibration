import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";

import { AuthProvider } from "./auth/AuthProvider";
import { RequireAuth } from "./auth/RequireAuth";
import { AppShell } from "./components/AppShell";
import { CertificatePage } from "./pages/CertificatePage";
import { HistoryPage } from "./pages/HistoryPage";
import { LoggerProfilePage } from "./pages/LoggerProfilePage";
import { LoginPage } from "./pages/LoginPage";
import { NewCalibrationPage } from "./pages/NewCalibrationPage";
import { OverviewPage } from "./pages/OverviewPage";
import { RunDetailPage } from "./pages/RunDetailPage";
import { SettingsPage } from "./pages/SettingsPage";
import { UpcomingPage } from "./pages/UpcomingPage";

const qc = new QueryClient();

export default function App() {
  return (
    <QueryClientProvider client={qc}>
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route
              element={
                <RequireAuth>
                  <AppShell />
                </RequireAuth>
              }
            >
              <Route index element={<OverviewPage />} />
              <Route path="calibrations" element={<HistoryPage />} />
              <Route path="calibrations/:id" element={<RunDetailPage />} />
              <Route path="upcoming" element={<UpcomingPage />} />
              <Route path="new" element={<NewCalibrationPage />} />
              <Route path="loggers" element={<LoggerProfilePage />} />
              <Route path="certificate" element={<CertificatePage />} />
              <Route path="settings" element={<SettingsPage />} />
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
