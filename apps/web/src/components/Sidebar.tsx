import { X } from "lucide-react";
import { NavLink } from "react-router-dom";

import { useAuth } from "../auth/useAuth";
import styles from "./AppShell.module.css";

const NAV: { to: string; label: string; adminOnly?: boolean }[] = [
  { to: "/", label: "Overview" },
  { to: "/calibrations", label: "Calibrations" },
  { to: "/new", label: "New calibration" },
  { to: "/upcoming", label: "Upcoming" },
  { to: "/loggers", label: "Loggers" },
  { to: "/certificate", label: "Cert lookup" },
  { to: "/settings", label: "Settings" },
  { to: "/admin/users", label: "Users", adminOnly: true },
];

interface Props {
  open?: boolean;
  onClose?: () => void;
}

export function Sidebar({ open, onClose }: Props) {
  const { user } = useAuth();
  return (
    <aside className={`${styles.sidebar} ${open ? styles.sidebarOpen : ""}`}>
      <div className={styles.brand}>
        ITE Calibration
        <button className={styles.sidebarClose} onClick={onClose} aria-label="Close navigation">
          <X size={18} />
        </button>
      </div>
      {NAV.filter((n) => !n.adminOnly || user?.role === "admin").map((n) => (
        <NavLink
          key={n.to}
          to={n.to}
          end={n.to === "/"}
          className={({ isActive }) =>
            isActive ? `${styles.navItem} ${styles.navItemActive}` : styles.navItem
          }
          onClick={onClose}
        >
          {n.label}
        </NavLink>
      ))}
    </aside>
  );
}
