import XCTest
@testable import EconomyKit

final class ScoringEngineTests: XCTestCase {

    private let rate: Decimal = 100          // ₹100/min — round numbers for clarity
    private let z = 240                      // potential 240 min → ₹24,000

    private func deepWork(id: String = "dw") -> ScoringHabit {
        ScoringHabit(id: id, kind: .build, usesLoggedDuration: true)
    }
    private func buildFlat(id: String = "b", reward: Int = 30, target: Int? = nil) -> ScoringHabit {
        ScoringHabit(id: id, kind: .build, rewardMinutes: reward, targetPerDay: target)
    }
    private func breakHabit(id: String = "cig", cost: Int = 30) -> ScoringHabit {
        ScoringHabit(id: id, kind: .breakHabit, costMinutes: cost)
    }

    // MARK: floor at zero

    func testHeavySlipDayFloorsAtZero() {
        let r = ScoringEngine.score(
            habits: [deepWork(), breakHabit(cost: 200)],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 60),
                   ScoringLog(habitID: "cig"), ScoringLog(habitID: "cig")],
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        // earned 60, honesty +10 (2×5), slips −400 → net −330 → floored
        XCTAssertEqual(r.keptAmount, 0)
        XCTAssertGreaterThanOrEqual(r.keptAmount, 0)
        XCTAssertGreaterThanOrEqual(r.slippedAmount, 0)
    }

    func testKeptNeverNegativeEvenWithNoEarnings() {
        let r = ScoringEngine.score(
            habits: [breakHabit()],
            logs: [ScoringLog(habitID: "cig")],
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        XCTAssertEqual(r.keptAmount, 0)
    }

    // MARK: honesty bonus softens but never erases the sting (cost > bonus)

    func testHonestyBonusReducesButDoesNotEraseSlipCost() {
        // Above the floor so the arithmetic is visible: earn plenty first.
        let withSlip = ScoringEngine.score(
            habits: [deepWork(), breakHabit(cost: 30)],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 120), ScoringLog(habitID: "cig")],
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        let noSlip = ScoringEngine.score(
            habits: [deepWork(), breakHabit(cost: 30)],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 120)],
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        // slip nets (honesty 5 − cost 30) = −25 min → −₹2,500 vs the no-slip day
        XCTAssertEqual(noSlip.keptAmount - withSlip.keptAmount, Decimal(25) * rate)
        XCTAssertLessThan(withSlip.keptAmount, noSlip.keptAmount) // still stings
    }

    // MARK: farming guard

    func testFlatBuildDefaultsToOncePerDay() {
        let r = ScoringEngine.score(
            habits: [buildFlat(reward: 30, target: nil)],
            logs: Array(repeating: ScoringLog(habitID: "b"), count: 5),
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        XCTAssertEqual(r.grossEarnedMinutes, 30) // credited once, not 5×
    }

    func testFlatBuildHonoursTargetPerDay() {
        let r = ScoringEngine.score(
            habits: [buildFlat(reward: 10, target: 3)],
            logs: Array(repeating: ScoringLog(habitID: "b"), count: 5),
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        XCTAssertEqual(r.grossEarnedMinutes, 30) // 3 credited × 10
    }

    func testDeepWorkIsNotCapped() {
        let r = ScoringEngine.score(
            habits: [deepWork()],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 90),
                   ScoringLog(habitID: "dw", durationMinutes: 90)],
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        XCTAssertEqual(r.grossEarnedMinutes, 180)
        XCTAssertEqual(r.deepWorkMinutes, 180)
    }

    // MARK: streak multiplies earnings only, capped, never touches deductions

    func testStreakMultipliesEarningsNotHonestyOrSlips() {
        let r = ScoringEngine.score(
            habits: [deepWork(), breakHabit(cost: 30)],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 100), ScoringLog(habitID: "cig")],
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.5)
        // earnings 100×1.5 = 150, honesty +5 (flat), slip −30 → 125 min → ₹12,500
        XCTAssertEqual(r.keptAmount, Decimal(125) * rate)
    }

    func testStreakMultiplierClampedToCap() {
        let r = ScoringEngine.score(
            habits: [deepWork()],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 100)],
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 9.0)
        XCTAssertEqual(r.streakMultiplier, 1.5)
        XCTAssertEqual(r.keptAmount, Decimal(150) * rate)
    }

    // MARK: kept/slipped split vs potential

    func testKeptPlusSlippedEqualsPotentialBelowCeiling() {
        let r = ScoringEngine.score(
            habits: [deepWork()],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 100)],
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        XCTAssertEqual(r.keptAmount + r.slippedAmount, r.potentialAmount)
    }

    func testOverachievingClampsSlippedToZero() {
        let r = ScoringEngine.score(
            habits: [deepWork()],
            logs: [ScoringLog(habitID: "dw", durationMinutes: 400)], // > Z of 240
            perMinuteRate: rate, potentialZMinutes: z, streakMultiplier: 1.0)
        XCTAssertEqual(r.slippedAmount, 0)
        XCTAssertGreaterThan(r.keptAmount, r.potentialAmount)
    }

    // MARK: honesty bonus config invariant

    func testHonestyBonusIsPositiveAndSmall() {
        XCTAssertGreaterThan(Tuning.honestyBonusMinutes, 0)
        // must be smaller than a typical slip cost so slips still sting
        XCTAssertLessThan(Tuning.honestyBonusMinutes, 30)
    }
}
