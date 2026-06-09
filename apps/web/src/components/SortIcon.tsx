import { ChevronDown, ChevronUp, ChevronsUpDown } from "lucide-react";

export type SortDir = "asc" | "desc";

interface SortIconProps {
  active: boolean;
  dir: SortDir;
  /** CSS class applied to the inactive (up+down) icon — pass your module's muted class. */
  className?: string;
}

export function SortIcon({ active, dir, className }: SortIconProps) {
  if (!active)
    return <ChevronsUpDown size={12} aria-hidden="true" className={className} />;
  return dir === "asc"
    ? <ChevronUp  size={12} aria-hidden="true" />
    : <ChevronDown size={12} aria-hidden="true" />;
}
