import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { StatusPill } from "./StatusPill";

describe("StatusPill", () => {
  it("renders a labeled pill for the invalid verdict", () => {
    render(<StatusPill value="invalid" />);
    expect(screen.getByText("Invalid")).toBeInTheDocument();
  });

  it("renders a labeled pill for the partial run status", () => {
    render(<StatusPill value="partial" />);
    expect(screen.getByText("Partial")).toBeInTheDocument();
  });
});
