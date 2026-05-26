import { describe, expect, it, vi } from "vitest";

import { apiFetch, ApiError } from "./client";

describe("apiFetch", () => {
  it("returns parsed JSON on 200", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ status: "ok" }),
    } as Response);
    const data = await apiFetch<{ status: string }>("/api/health");
    expect(data).toEqual({ status: "ok" });
  });

  it("throws ApiError on non-OK", async () => {
    global.fetch = vi.fn().mockResolvedValue({
      ok: false,
      status: 401,
      json: async () => ({ detail: "nope" }),
    } as Response);
    await expect(apiFetch("/api/auth/me")).rejects.toBeInstanceOf(ApiError);
  });

  it("sends credentials include", async () => {
    const f = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({}),
    } as Response);
    global.fetch = f;
    await apiFetch("/api/health");
    expect(f).toHaveBeenCalledWith(
      "/api/health",
      expect.objectContaining({ credentials: "include" }),
    );
  });

  it("serializes json body and sets Content-Type", async () => {
    const f = vi.fn().mockResolvedValue({
      ok: true,
      status: 204,
      json: async () => ({}),
    } as Response);
    global.fetch = f;
    await apiFetch("/api/auth/login", { method: "POST", json: { email: "a@b", password: "p" } });
    const call = f.mock.calls[0];
    expect(call[1].body).toBe(JSON.stringify({ email: "a@b", password: "p" }));
    expect(call[1].headers).toMatchObject({ "Content-Type": "application/json" });
  });
});
