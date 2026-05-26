import { render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import App from "./App";

describe("App", () => {
  it("renders login page when unauthenticated", async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      ok: false, status: 401, json: async () => ({}),
    } as Response);
    render(<App />);
    await waitFor(() =>
      expect(screen.getByText(/sign in to continue/i)).toBeInTheDocument(),
    );
  });
});
