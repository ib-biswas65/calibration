import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import { describe, expect, it, vi } from "vitest";

import { AuthProvider } from "../auth/AuthProvider";
import { LoginPage } from "./LoginPage";

function wrap() {
  return render(
    <MemoryRouter>
      <AuthProvider>
        <LoginPage />
      </AuthProvider>
    </MemoryRouter>,
  );
}

describe("LoginPage", () => {
  it("shows email + password fields and a submit button", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false, status: 401, json: async () => ({}),
    } as Response);
    wrap();
    await waitFor(() => screen.getByRole("button", { name: /sign in/i }));
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument();
  });

  it("shows validation error for invalid email", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false, status: 401, json: async () => ({}),
    } as Response);
    wrap();
    const user = userEvent.setup();
    await user.type(screen.getByLabelText(/email/i), "not-an-email");
    await user.type(screen.getByLabelText(/password/i), "anything");
    await user.click(screen.getByRole("button", { name: /sign in/i }));
    expect(await screen.findByText(/valid email/i)).toBeInTheDocument();
  });
});
