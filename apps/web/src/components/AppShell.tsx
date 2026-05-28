import { useState } from "react";
import { Outlet } from "react-router-dom";

import { Sidebar } from "./Sidebar";
import { Topbar } from "./Topbar";
import styles from "./AppShell.module.css";

export function AppShell() {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  return (
    <div className={styles.shell}>
      {sidebarOpen && (
        <div className={styles.overlay} onClick={() => setSidebarOpen(false)} aria-hidden="true" />
      )}
      <Sidebar open={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className={styles.main}>
        <Topbar onMenuClick={() => setSidebarOpen(true)} />
        <div className={styles.content}>
          <Outlet />
        </div>
      </div>
    </div>
  );
}
