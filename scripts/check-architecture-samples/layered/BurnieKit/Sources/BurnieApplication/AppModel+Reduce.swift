// expect: A-1
/// A file that extends AppModel still can't make a top-level helper public.
public typealias Reduce = (Int) -> Int

extension AppModel {
    public var isIdle: Bool { true }
}
