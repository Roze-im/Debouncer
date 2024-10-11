//
//  Throttler.swift
//  RozeEngine-Swift
//
//  Created by Thibaud David on 31/05/2021.
//

import Foundation

/// Throttler allows calling a method with a max interval limit between calls
/// https://rxmarbles.com/#throttle
/// Throttling allows a periodic call of our task, meanwhile a debouncer
/// would only call the last task during the same spamming interval
/// Eg: We want a periodic refresh during spamming a "scrollViewDidScroll" event
/// instead of only getting the last task being called
public final class Throttler {
  public let queue: DispatchQueue

  private var worker: DispatchWorkItem?
  private var lastExecutionDate: Date?

  public init(queue: DispatchQueue = .main) {
      self.queue = queue
  }

  /// By design, task will **never** be called synchronously.
  public func throttle(with maxInterval: TimeInterval = 0.3, task: @escaping () -> Void) {
      abortPreviousTask()

        /**
            Task is being captured by a nullable closure, to be able to manually release
            task along with said closure.
            When a dispatchWorkItem gets cancelled, its block is being released,
            however when `.perform()` getting is called, (aka asyncAfter expires here),
            the worker **doesn't** get released. This is most probably due to @convention
            being used on DispatchWorkItem's block.
        */
        var taskWrapper: (() -> Void)? = task
        let worker = DispatchWorkItem { [weak self] in
            self?.lastExecutionDate = Date()
            taskWrapper?()
            taskWrapper = nil
        }
        if let lastExecutionDate = lastExecutionDate {
            let interval = Date().timeIntervalSince(lastExecutionDate)
            let delay = interval > maxInterval ? 0 : (maxInterval - interval)
            queue.asyncAfter(deadline: .now() + delay, execute: worker)
        } else {
            queue.async(execute: worker)
        }
        self.worker = worker
      }

      public func abortPreviousTask() {
          worker?.cancel()
          worker = nil
      }
}
