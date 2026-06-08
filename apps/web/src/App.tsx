import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";

import { AuthProvider } from "./auth/AuthProvider";
import { ErrorBoundary } from "./components/ErrorBoundary";
import { RequireAuth } from "./auth/RequireAuth";
import { AppShell } from "./components/AppShell";
import { ToastProvider } from "./components/Toast";
import { AdminUsersPage } from "./pages/AdminUsersPage";
import { CertificatePage } from "./pages/CertificatePage";
import { RegisterPage } from "./pages/RegisterPage";
import { ResetPasswordPage } from "./pages/ResetPasswordPage";
import { HistoryPage } from "./pages/HistoryPage";
import { LoggersPage } from "./pages/LoggersPage";
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
          <ToastProvider>
            <ErrorBoundary>
            <Routes>
              <Route path="/login" element={<LoginPage />} />
              <Route path="/register" element={<RegisterPage />} />
              <Route path="/reset-password" element={<ResetPasswordPage />} />
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
                <Route path="loggers" element={<LoggersPage />} />
                <Route path="certificate" element={<CertificatePage />} />
                <Route path="settings" element={<SettingsPage />} />
                <Route path="admin/users" element={<AdminUsersPage />} />
              </Route>
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
            </ErrorBoundary>
          </ToastProvider>
        </AuthProvider>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
