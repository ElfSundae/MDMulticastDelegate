#import <Foundation/Foundation.h>

/**
 * This class provides multicast delegate functionality. That is:
 * - it provides a means for managing a list of delegates
 * - any method invocations to an instance of this class are automatically forwarded to all delegates
 *
 * For example:
 *
 * // Make this method call on every added delegate (there may be several)
 * [multicastDelegate cog:self didFindThing:thing];
 *
 * This allows multiple delegates to be added to an xmpp stream or any xmpp module,
 * which in turn makes development easier as there can be proper separation of logically different code sections.
 *
 * In addition, this makes module development easier,
 * as multiple delegates can usually be handled in a manner similar to the traditional single delegate paradigm.
 *
 * This class also provides proper support for GCD queues.
 * So each delegate specifies which queue they would like their delegate invocations to be dispatched onto.
 *
 * All delegate dispatching is done asynchronously (which is a critically important architectural design).
 **/

NS_ASSUME_NONNULL_BEGIN

@interface MDMulticastDelegate<__covariant DelegateType> : NSObject

/**
 Add a delegate object to the dispatch table with the main dispatch queue.
 @discussion The delegate methods will be invoked on the main dispatch queue.

 @param delegate target to invoke
 */
- (void)addDelegate:(DelegateType)delegate;

/**
 Add a delegate object to the dispatch table with a given dispatch queue.
 @discussion The delegate methods will be invoked on the given dispatch queue.

 @param delegate target to invoke
 @param delegateQueue queue to dispatch for invoking
 */
- (void)addDelegate:(DelegateType)delegate delegateQueue:(dispatch_queue_t)delegateQueue;

/**
 Remove a delegate object from the dispatch table.
 @discussion You don't need to remove a delegate object in its dealloc method.

 @param delegate target to remove
 */
- (void)removeDelegate:(DelegateType)delegate;

/**
 Remove a delegate object specifying a given dispatch queue from the dispatch table.
 @discussion You don't need to remove a delegate object in its dealloc method.

 @param delegate target to remove
 @param delegateQueue queue to dispatch for invoking
 */
- (void)removeDelegate:(DelegateType)delegate delegateQueue:(nullable dispatch_queue_t)delegateQueue;

/**
 Remove all delegate objects from the dispatch table.
 */
- (void)removeAllDelegates;

/**
 Count of delegate-queue pairs.
 */
- (NSUInteger)count;

/**
 Count of delegate objects.
 */
- (NSUInteger)countOfDelegates;

/**
 Count of delegate-queue pairs of which delegate is kind of the given class.

 @param aClass class of delegate
 */
- (NSUInteger)countOfClass:(Class)aClass;

/**
 Count of delegate-queue pairs of which delegate can respond to the specified selector.

 @param aSelector selector to repsond for delegates
 */
- (NSUInteger)countForSelector:(SEL)aSelector;

/**
 Detects whether exist any delegate object that can respond to the given selector.

 @param aSelector selector to repsond for delegates
 */
- (BOOL)hasDelegateThatRespondsToSelector:(SEL)aSelector;

/**
 Applies a given block to the entries of the dispatch table.

 @param block A block to operate
 */
- (void)enumerateDelegatesAndQueuesUsingBlock:(void (NS_NOESCAPE ^)(DelegateType delegate, dispatch_queue_t delegateQueue, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
