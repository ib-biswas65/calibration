import { Menu } from "lucide-react";
import { useNavigate } from "react-router-dom";

import { useAuth } from "../auth/useAuth";
import styles from "./AppShell.module.css";

interface Props {
  onMenuClick?: () => void;
}

export function Topbar({ onMenuClick }: Props) {
  const { user, logout } = useAuth();
  const nav = useNavigate();
  return (
    <header className={styles.topbar}>
      <button
        className={styles.hamburger}
        onClick={onMenuClick}
        aria-label="Open navigation"
      >
        <Menu size={20} aria-hidden="true" />
      </button>
      <div style={{ fontWeight: 600, fontSize: 14 }}>Dashboard</div>
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
