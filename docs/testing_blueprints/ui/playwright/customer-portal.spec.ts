import { test, expect } from "@playwright/test";

test.describe("Customer portal", () => {
    test("create customer and display success state", async ({ page }) => {
        await page.goto("http://localhost:3000/customers");

        await page.getByRole("button", { name: "New Customer" }).click();
        await page.getByLabel("Name").fill("Acme Portal Co");
        await page.getByLabel("Email").fill("portal@acme.test");
        await page.getByRole("button", { name: "Create" }).click();

        await expect(page.getByText("Customer created successfully")).toBeVisible();
        await expect(page.getByText("Acme Portal Co")).toBeVisible();
    });

    test("show validation errors for invalid form", async ({ page }) => {
        await page.goto("http://localhost:3000/customers/new");

        await page.getByRole("button", { name: "Create" }).click();

        await expect(page.getByText("Email is required")).toBeVisible();
    });
});
