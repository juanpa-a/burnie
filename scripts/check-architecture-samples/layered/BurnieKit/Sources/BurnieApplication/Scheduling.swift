// expect: A-1
import BurnieDomain

/// Pure scheduling decisions, made public by mistake.
public enum Scheduling {
    public static func canRun(_ job: JobState) -> Bool { job.running == nil }
}
