import { describe, expect, it } from "bun:test";

type Customer = {
    id: string;
    name: string;
    email: string;
};

function validateCustomer(input: Partial<Customer>) {
    const errors: string[] = [];

    if (!input.name || input.name.trim().length < 2) {
        errors.push("name");
    }

    if (!input.email || !input.email.includes("@")) {
        errors.push("email");
    }

    return {
        valid: errors.length === 0,
        errors,
    };
}

describe("customer validator", () => {
    it("accepts valid customer payload", () => {
        const result = validateCustomer({
            name: "Bun Holdings",
            email: "qa@bun.test",
        });

        expect(result.valid).toBe(true);
        expect(result.errors.length).toBe(0);
    });

    it("returns errors for invalid payload", () => {
        const result = validateCustomer({
            name: "x",
            email: "invalid",
        });

        expect(result.valid).toBe(false);
        expect(result.errors).toContain("name");
        expect(result.errors).toContain("email");
    });
});
