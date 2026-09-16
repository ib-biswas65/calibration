import { describe, expect, it } from "vitest";
import { isFailingVerdict } from "./types";

describe("isFailingVerdict", () => {
  it("treats fail as failing", () => {
    expect(isFailingVerdict("fail")).toBe(true);
  });

  it("treats invalid as failing", () => {
    expect(isFailingVerdict("invalid")).toBe(true);
  });

  it("treats pass as not failing", () => {
    expect(isFailingVerdict("pass")).toBe(false);
  });

  it("treats adjusted as not failing", () => {
    expect(isFailingVerdict("adjusted")).toBe(false);
  });
});
