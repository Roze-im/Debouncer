//
//  File.swift
//  
//
//  Created by Benjamin Garrigues on 02/07/2024.
//

import Foundation

/// Variation of the Debouncer class with an accumulation function that lets one
/// accumulate data being debounced
public final class AccumulatingDebouncer<Buffer> {

    public typealias AccumulationFunction = (inout Buffer) -> Void

    let taskQueue: DispatchQueue

    private var worker: DispatchWorkItem?

    private var initialBufferValue: Buffer
    private var buffer: Synchronized<Buffer>
    public init(
        accumulationQueue: DispatchQueue = .main,
        taskQueue: DispatchQueue = .main,
        initialBufferValue: Buffer
    ) {
        self.taskQueue = taskQueue
        self.initialBufferValue = initialBufferValue
        self.buffer = .init(initialBufferValue, accessQueue: accumulationQueue)
    }

    public func debounce(
        for delay: TimeInterval = 0.3,
        accumulate: AccumulationFunction,
        task: @escaping (Buffer) -> Void
    ) {
        abortPreviousTask()

        // accumulate
        buffer { accumulate(&$0) }
        /**
            Task is being captured by a nullable closure, to be able to manually release
            task along with said closure.
            When a dispatchWorkItem gets cancelled, its block is being released,
            however when `.perform()` getting is called, (aka asyncAfter expires here),
            the worker **doesn't** get released. This is most probably due to @convention
            being used on DispatchWorkItem's block.
         */
        var taskWrapper: ((Buffer) -> Void)? = task
        let worker = DispatchWorkItem { [weak self] in
            guard let self else { return }
            taskWrapper?(buffer.getValueSync())
            taskWrapper = nil
            // resets the buffer
            buffer.setValueSync(initialBufferValue)
        }
        taskQueue.asyncAfter(deadline: .now() + delay, execute: worker)
        self.worker = worker
    }

    public func abortPreviousTask() {
        worker?.cancel()
        worker = nil
    }
}
