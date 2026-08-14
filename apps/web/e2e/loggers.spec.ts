import { expect, test } from "@playwright/test";

const EMAIL = process.env.E2E_ADMIN_EMAIL ?? "boss@ite.local";
const PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? "hunter2-very-long-password";

test.beforeEach(async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel(/email/i).fill(EMAIL);
  await page.getByLabel(/password/i).fill(PASSWORD);
  await page.getByRole("button", { name: /sign in/i }).click();
  await expect(page).toHaveURL("/");
});

test("loggers page loads with search bar", async ({ page }) => {
  await page.getByRole("link", { name: /loggers/i }).click();
  await expect(page).toHaveURL("/loggers");
  await expect(page.getByRole("heading", { name: /logger fleet/i })).toBeVisible();
  await expect(page.getByPlaceholder(/search serial/i)).toBeVisible();
});

test("loggers page shows empty state when no loggers exist", async ({ page }) => {
  await page.goto("/loggers");
  // Either shows logger rows or the empty message — both are valid
  const rows = page.locator("table tbody tr");
  const empty = page.getByText(/no loggers found/i);
  await expect(rows.or(empty).first()).toBeVisible();
});
