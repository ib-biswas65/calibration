import {
  LayoutGrid,
  ClipboardList,
  PlusCircle,
  Clock,
  Thermometer,
  Search,
  Settings as SettingsIcon,
  Users2,
  X,
} from "lucide-react";
import { NavLink } from "react-router-dom";

import { useAuth } from "../auth/useAuth";
import styles from "./AppShell.module.css";

const NAV: { to: string; label: string; icon: typeof LayoutGrid; adminOnly?: boolean }[] = [
  { to: "/", label: "Overview", icon: LayoutGrid },
  { to: "/calibrations", label: "Calibrations", icon: ClipboardList },
  { to: "/new", label: "New calibration", icon: PlusCircle },
  { to: "/upcoming", label: "Upcoming", icon: Clock },
  { to: "/loggers", label: "Loggers", icon: Thermometer },
  { to: "/certificate", label: "Cert lookup", icon: Search },
  { to: "/settings", label: "Settings", icon: SettingsIcon },
  { to: "/admin/users", label: "Users", icon: Users2, adminOnly: true },
];

interface Props {
  open?: boolean;
  onClose?: () => void;
}

export function Sidebar({ open, onClose }: Props) {
  const { user } = useAuth();
  return (
    <aside className={`${styles.sidebar} ${open ? styles.sidebarOpen : ""}`}>
      <div className={styles.brandBlock}>
        <div className={styles.brand}>
          <svg className={styles.brandMark} viewBox="0 0 32 32" fill="none" aria-hidden="true">
            <path d="M16 3c5 6.2 9 11 9 15.4C25 23.9 21 27 16 27S7 23.9 7 18.4C7 14 11 8.2 16 3Z" fill="#179e38" />
            <path d="M16 9c2.6 3.4 4.6 6 4.6 8.6a4.6 4.6 0 0 1-9.2 0C11.4 15 13.4 12.4 16 9Z" fill="#eceee6" fillOpacity=".9" />
          </svg>
          <span>ITE Calibration</span>
          <button className={styles.sidebarClose} onClick={onClose} aria-label="Close navigation">
            <X size={18} />
          </button>
        </div>
        <div className={styles.brandQuartet} aria-hidden="true">
          <span style={{ background: "#d5342e" }} />
          <span style={{ background: "#fab72b" }} />
          <span style={{ background: "#1fa9c9" }} />
          <span style={{ background: "#179e38" }} />
        </div>
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
          <n.icon size={16} aria-hidden="true" />
          {n.label}
        </NavLink>
      ))}
    </aside>
  );
}
