import { useNavigate } from "react-router-dom";

import { useAuth } from "../auth/useAuth";
import styles from "./AppShell.module.css";

export function Topbar() {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  return (
    <header className={styles.topbar}>
      <div style={{ fontWeight: 600 }}>Dashboard</div>
      <div className={styles.userPill}>
        <span>{user?.full_name} · {user?.role}</span>
        <button
          className={styles.logout}
          onClick={async () => {
            await logout();
            nav("/login", { replace: true });
          }}
        >
          Log out
        </button>
      </div>
    </header>
  );
}
