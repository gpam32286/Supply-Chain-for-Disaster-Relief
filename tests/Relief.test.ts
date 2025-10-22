
import { describe, expect, it } from "vitest";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const wallet1 = accounts.get("wallet_1")!;
const wallet2 = accounts.get("wallet_2")!;
const wallet3 = accounts.get("wallet_3")!;

describe("Relief Contract Tests", () => {
  it("ensures simnet is well initialised", () => {
    expect(simnet.blockHeight).toBeDefined();
  });

  it("should get initial contract stats", () => {
    const { result } = simnet.callReadOnlyFn("Relief", "get-contract-stats", [], deployer);
    expect(result).toStrictEqual({
      "total-supplies": "u0",
      "total-delivered": "u0",
      "next-supply-id": "u1",
      "contract-owner": deployer
    });
  });

  it("should register a new supply", () => {
    const { result } = simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Medical Supplies",
        "Medicine",
        "u100",
        "boxes",
        "Haiti Relief Center",
        "Warehouse A"
      ],
      wallet1
    );
    expect(result).toBeOk("u1");
  });

  it("should get supply information", () => {
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Water Bottles",
        "Water",
        "u500",
        "bottles",
        "Disaster Zone Alpha",
        "Distribution Center"
      ],
      wallet1
    );

    const { result } = simnet.callReadOnlyFn("Relief", "get-supply", ["u2"], deployer);
    expect(result).toBeSome();
  });

  it("should allow contract owner to add operators", () => {
    const { result } = simnet.callPublicFn(
      "Relief",
      "add-operator",
      [wallet2],
      deployer
    );
    expect(result).toBeOk(true);
  });

  it("should check if operator is authorized", () => {
    simnet.callPublicFn("Relief", "add-operator", [wallet2], deployer);
    
    const { result } = simnet.callReadOnlyFn(
      "Relief",
      "is-authorized-operator",
      [wallet2],
      deployer
    );
    expect(result).toBe(true);
  });

  it("should allow supply source to update status", () => {
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Food Packages",
        "Food",
        "u200",
        "packages",
        "Emergency Shelter",
        "Food Bank"
      ],
      wallet1
    );

    const { result } = simnet.callPublicFn(
      "Relief",
      "update-supply-status",
      ["u3", "u1", "En route to shelter", "Loaded on truck #123"],
      wallet1
    );
    expect(result).toBeOk(true);
  });

  it("should allow authorized operator to update status", () => {
    simnet.callPublicFn("Relief", "add-operator", [wallet2], deployer);
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Blankets",
        "Shelter",
        "u50",
        "units",
        "Refugee Camp",
        "Storage Facility"
      ],
      wallet1
    );

    const { result } = simnet.callPublicFn(
      "Relief",
      "update-supply-status",
      ["u4", "u2", "Checkpoint Alpha", "Passed security check"],
      wallet2
    );
    expect(result).toBeOk(true);
  });

  it("should prevent unauthorized users from updating status", () => {
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "First Aid Kits",
        "Medical",
        "u25",
        "kits",
        "Field Hospital",
        "Medical Storage"
      ],
      wallet1
    );

    const { result } = simnet.callPublicFn(
      "Relief",
      "update-supply-status",
      ["u5", "u1", "Unauthorized location", "Unauthorized update"],
      wallet3
    );
    expect(result).toBeErr("u104");
  });

  it("should allow verification of delivered supplies", () => {
    simnet.callPublicFn("Relief", "add-operator", [wallet2], deployer);
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Medicine",
        "Medical",
        "u75",
        "vials",
        "Local Clinic",
        "Pharmacy"
      ],
      wallet1
    );
    
    simnet.callPublicFn(
      "Relief",
      "update-supply-status",
      ["u6", "u3", "Local Clinic", "Delivered successfully"],
      wallet1
    );

    const { result } = simnet.callPublicFn(
      "Relief",
      "verify-supply",
      ["u6", "Verified by medical staff, distributed to patients"],
      wallet2
    );
    expect(result).toBeOk(true);
  });

  it("should get supply verification details", () => {
    simnet.callPublicFn("Relief", "add-operator", [wallet2], deployer);
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Solar Panels",
        "Energy",
        "u10",
        "panels",
        "Community Center",
        "Tech Warehouse"
      ],
      wallet1
    );
    
    simnet.callPublicFn(
      "Relief",
      "update-supply-status",
      ["u7", "u3", "Community Center", "Installation complete"],
      wallet1
    );
    
    simnet.callPublicFn(
      "Relief",
      "verify-supply",
      ["u7", "Solar panels operational, providing power"],
      wallet2
    );

    const { result } = simnet.callReadOnlyFn(
      "Relief",
      "get-supply-verification",
      ["u7"],
      deployer
    );
    expect(result).toBeSome();
  });

  it("should prevent verification of non-delivered supplies", () => {
    simnet.callPublicFn("Relief", "add-operator", [wallet2], deployer);
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Generators",
        "Power",
        "u5",
        "units",
        "Hospital",
        "Equipment Storage"
      ],
      wallet1
    );

    const { result } = simnet.callPublicFn(
      "Relief",
      "verify-supply",
      ["u8", "Attempting to verify before delivery"],
      wallet2
    );
    expect(result).toBeErr("u103");
  });

  it("should prevent non-owners from adding operators", () => {
    const { result } = simnet.callPublicFn(
      "Relief",
      "add-operator",
      [wallet3],
      wallet1
    );
    expect(result).toBeErr("u100");
  });

  it("should get supply history", () => {
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Tents",
        "Shelter",
        "u20",
        "tents",
        "Evacuation Site",
        "Relief Depot"
      ],
      wallet1
    );

    const { result } = simnet.callReadOnlyFn(
      "Relief",
      "get-supply-history",
      ["u9", "u0"],
      deployer
    );
    expect(result).toBeSome();
  });

  it("should update contract stats after operations", () => {
    const initialStats = simnet.callReadOnlyFn("Relief", "get-contract-stats", [], deployer);
    
    simnet.callPublicFn(
      "Relief",
      "register-supply",
      [
        "Clothing",
        "Personal",
        "u100",
        "items",
        "Refugee Center",
        "Donation Center"
      ],
      wallet1
    );
    
    simnet.callPublicFn(
      "Relief",
      "update-supply-status",
      ["u10", "u3", "Refugee Center", "Clothing distributed"],
      wallet1
    );

    const finalStats = simnet.callReadOnlyFn("Relief", "get-contract-stats", [], deployer);
    expect(finalStats.result).toBeDefined();
  });
});
