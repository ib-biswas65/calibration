import { expect, test } from "@playwright/test";

const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? "boss@ite.local";
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? "hunter2-very-long-password";

test("admin can log in, see overview, and log out", async ({ page }) => {
  await page.goto("/login");
  await expect(page.getByText(/sign in to continue/i)).toBeVisible();

  await page.getByLabel(/email/i).fill(ADMIN_EMAIL);
  await page.getByLabel(/password/i).fill(ADMIN_PASSWORD);
  await page.getByRole("button", { name: /sign in/i }).click();

  await expect(page).toHaveURL("/");
  await expect(page.getByRole("heading", { name: /overview/i })).toBeVisible();

  await page.getByRole("button", { name: /log out/i }).click();
  await expect(page).toHaveURL(/\/login$/);
});
