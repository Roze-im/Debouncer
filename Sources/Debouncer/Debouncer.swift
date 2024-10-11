//
//  Debouncer.swift
//  Roze
//
//  Created by Thibaud David on 24/11/2020.
//  Copyright © 2020 Roze. All rights reserved.
//

import Foundation

/// Debouncer allows calling a method a given delay after last debouncing call
/// https://rxmarbles.com/#throttleTime
/// See: Throttler to get a periodic call of task instead of only last ont getting executed
public final class Debouncer {
    let queue: DispatchQueue

    private var worker: DispatchWorkItem?

    /**
        Task is being captured by a nullable closure, to be able to manually release
        task along with said closure.
        When a dispatchWorkItem gets cancelled, its block is being released,
        however when `.perform()` getting is called, (aka asyncAfter expires here),
        the worker **doesn't** get released. This is most probably due to @convention
        being used on DispatchWorkItem's block.
     */
    var taskWrapper: (() -> Void)?

    public init(queue: DispatchQueue = .main) {
        self.queue = queue
    }

    public func debounce(for delay: TimeInterval = 0.3, task: @escaping () -> Void) {
        abortPreviousTask()

        taskWrapper = task
        let worker = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.taskWrapper?()
            self.taskWrapper = nil
        }
        queue.asyncAfter(deadline: .now() + delay, execute: worker)
        self.worker = worker
    }

    public func fire() {
        let task = taskWrapper
        abortPreviousTask()
        task?()
    }

    public func abortPreviousTask() {
        worker?.cancel()
        worker = nil
        taskWrapper = nil
    }
}
