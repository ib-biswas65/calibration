import { NavLink } from "react-router-dom";

import styles from "./AppShell.module.css";

const NAV: { to: string; label: string }[] = [
  { to: "/", label: "Overview" },
  { to: "/calibrations", label: "Calibrations" },
  { to: "/upcoming", label: "Upcoming" },
  { to: "/new", label: "New calibration" },
  { to: "/loggers", label: "Logger profile" },
  { to: "/certificate", label: "Certificate" },
  { to: "/settings", label: "Settings" },
];

export function Sidebar() {
  return (
    <aside className={styles.sidebar}>
      <div className={styles.brand}>ITE Calibration</div>
      {NAV.map((n) => (
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
