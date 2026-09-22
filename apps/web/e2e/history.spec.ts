import { expect, test } from "@playwright/test";

const EMAIL = process.env.E2E_ADMIN_EMAIL ?? "boss@example.com";
const PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? "hunter2-very-long-password";

test.beforeEach(async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel(/email/i).fill(EMAIL);
  await page.getByLabel("Password", { exact: true }).fill(PASSWORD);
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
  await expect(page.getByText(/no calibration runs found/i)).toBeVisible();
});

// Note: a "table page toggles between table and card view" test used to live here,
// but HistoryPage has no such toggle — that Table/Cards view switcher only exists on
// RunDetailPage. This was a copy-paste error from when the spec was originally written;
// there's no trace in HistoryPage.tsx or its CSS module of one ever being planned here.
// Removed rather than "fixed" since it tests a feature that doesn't exist on this page.
