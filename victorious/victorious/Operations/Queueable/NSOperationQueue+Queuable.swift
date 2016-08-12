//
//  NSOperationQueue+Queuable.swift
//  victorious
//
//  Created by Patrick Lynch on 2/23/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

private let sharedOperationQueue = NSOperationQueue()

extension NSOperationQueue {
    
    /// An application-wide default queue for all operations that are not required to
    /// execute on the main queue.
    static var v_globalBackgroundQueue: NSOperationQueue {
        return sharedOperationQueue
    }
    
    func v_dependentOperationsOf(operation: NSOperation) -> [NSOperation] {
        return operations.filter { $0.dependencies.contains(operation) }
    }
    
    func v_rechainOperation( operation: NSOperation, after dependency: NSOperation ) {
        
        // Rechain (transfer) completion block
        operation.addDependency( dependency )
        
        // Rechain (transfer) dependencies
        for dependent in v_dependentOperationsOf( dependency ) {
            dependent.addDependency( operation )
        }
    }
}

extension NSOperationQueue {
    func v_addOperation<T: Queueable where T : NSOperation>( operation: T, completion: T.CompletionBlockType? ) {
        if let completion = completion {
            // Turn completion block into an operation.
            let completionOperation = NSBlockOperation() {
                operation.executeCompletionBlock(completion)
            }
            // For all other dependent operations of the current operation, make them dependent on the completion block operation instead.
            // This has to happen before we set up completion block operation's dependency to avoid a dead lock.
            v_dependentOperationsOf(operation).forEach { $0.addDependency(completionOperation) }
            
            // Set up dependency for completion block operation and add it to queue.
            completionOperation.addDependency(operation)
            addOperation(completionOperation)
        }
        addOperation(operation)
    }
}

/// This is designed to be a simplified version of Queueable and will replace it.
/// Since FetcherOperation and FetcherRemoteOperatino still uses the original Queueable protocol,
/// we'll perform the replacement once core data is removed. Which I'll do next.
protocol Queueable2 {
    
    /// Conformers are required to define a completion block type that is
    /// specific to the actions it performs.  This allows calling code to have
    /// meaningful completion blocks that pass back results or other data.
    associatedtype Completion
    
    /// Conformers should define what type of Output it will generate.
    associatedtype Output
    
    /// The output generated by the operation
    var output: Output? { get }
    
    /// Conformers should speficy which queue the operation should be scheduled(queued) on.
    var scheduleQueue: NSOperationQueue { get }
    
    /// Adds the receiver to its default queue, with a completion block that'll run after the receiver's finished executing,
    /// and before the next operation starts.
    func queue(completion completion: Completion?)
    
    /// Adds the receiver to its default queue without completion block.
    func queue()
}

extension Queueable2 where Self: NSOperation {
    func queue(completion completion: ((output: Output) -> Void)?) {
        defer {
            scheduleQueue.addOperation(self)
        }
        
        guard let completion = completion else {
            return
        }
        
        let completionOperation = NSBlockOperation {
            guard let output = self.output else {
                assertionFailure("Received no output from async operation to pass through the completion handler.")
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                completion(output: output)
            }
        }
        completionOperation.addDependency(self)
        scheduleQueue.addOperation(completionOperation)
    }
    
    func queue() {
        queue(completion: nil)
    }
}

class SyncOperation<Output>: NSOperation, Queueable2 {
    
    // MARK: - Queueable2
    
    var scheduleQueue: NSOperationQueue {
        fatalError()
    }
    
    private(set) var output: Output?
    
    // MARK: - Operation Execution
    
    func execute() -> Output {
        fatalError()
    }
    
    override final func main() {
        output = execute()
    }
}

private let asyncScheduleQueue = NSOperationQueue()

class AsyncOperation<Output>: NSOperation, Queueable2 {
    
    // MARK: - Queueable2
    
    let queue = NSOperationQueue.v_globalBackgroundQueue
    
    final let scheduleQueue = asyncScheduleQueue
    
    var executionQueue: NSOperationQueue {
        fatalError()
    }
    
    private(set) var output: Output?
    
    // MARK: - Operation Execution
    
    func execute(finish: (output: Output) -> Void) {
        fatalError()
    }
    
    override final func main() {
        scheduleQueue.suspended = true
        
        executionQueue.addOperationWithBlock {
            self.executeWithCompletion()
        }
    }
    
    private func executeWithCompletion() {
        execute { output in
            self.output = output
            self.scheduleQueue.suspended = false
        }
    }
}
