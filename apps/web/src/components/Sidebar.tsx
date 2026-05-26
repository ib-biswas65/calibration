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

export function Sidebar() {
  const { user } = useAuth();
  return (
    <aside className={styles.sidebar}>
      <div className={styles.brand}>ITE Calibration</div>
      {NAV.filter((n) => !n.adminOnly || user?.role === "admin").map((n) => (
        <NavLink
          key={n.to}
          to={n.to}
          end={n.to === "/"}
          className={({ isActive }) =>
            isActive ? `${styles.navItem} ${styles.navItemActive}` : styles.navItem
          }
        >
          {n.label}
        </NavLink>
      ))}
    </aside>
  );
}
