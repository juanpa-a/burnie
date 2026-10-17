import Foundation

extension Int {
    /// `self + other`, or the bound it ran past instead of trapping (D-5).
    func saturatingAdding(_ other: Int) -> Int {
        let (sum, overflow) = addingReportingOverflow(other)
        guard overflow else { return sum }
        return other > 0 ? .max : .min
    }

    /// `self - other`, or the bound it ran past instead of trapping (D-5).
    func saturatingSubtracting(_ other: Int) -> Int {
        let (difference, overflow) = subtractingReportingOverflow(other)
        guard overflow else { return difference }
        return other < 0 ? .max : .min
    }
}
