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

test("history page loads and shows table", async ({ page }) => {
  await page.getByRole("link", { name: /calibrations/i }).click();
  await expect(page).toHaveURL("/calibrations");
  await expect(page.getByRole("heading", { name: /calibration history/i })).toBeVisible();
});

test("history page search filters runs", async ({ page }) => {
  await page.goto("/calibrations");
  const search = page.getByPlaceholder(/search/i);
  await search.fill("no-match-xyzzy");
  await expect(page.getByText(/no runs/i)).toBeVisible();
});

test("history page toggles between table and card view", async ({ page }) => {
  await page.goto("/calibrations");
  const toggle = page.getByRole("button", { name: /cards/i });
  await toggle.click();
  await expect(page.getByRole("button", { name: /table/i })).toBeVisible();
});
