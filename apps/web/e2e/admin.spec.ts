import { expect, test } from "@playwright/test";

const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? "boss@example.com";
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? "hunter2-very-long-password";

test.beforeEach(async ({ page }) => {
  await page.goto("/login");
  await page.getByLabel(/email/i).fill(ADMIN_EMAIL);
  await page.getByLabel("Password", { exact: true }).fill(ADMIN_PASSWORD);
  await page.getByRole("button", { name: /sign in/i }).click();
  await expect(page).toHaveURL("/");
});

test("admin can see Users link in sidebar", async ({ page }) => {
  await expect(page.getByRole("link", { name: /users/i })).toBeVisible();
});

test("admin users page lists users", async ({ page }) => {
  await page.getByRole("link", { name: /users/i }).click();
  await expect(page).toHaveURL("/admin/users");
  await expect(page.getByRole("heading", { name: /user management/i })).toBeVisible();
  // the admin account itself should be in the list
  await expect(page.getByText(ADMIN_EMAIL)).toBeVisible();
});

test("admin can invite a new user and see setup URL", async ({ page }) => {
  await page.goto("/admin/users");
  await page.getByRole("button", { name: /invite user/i }).click();
  const unique = `e2e-${Date.now()}@example.com`;
  await page.getByLabel(/email/i).fill(unique);
  await page.getByLabel(/full name/i).fill("E2E Test User");
  await page.getByRole("button", { name: /create user/i }).click();
  await expect(page.getByText(/setup link/i)).toBeVisible();
});
