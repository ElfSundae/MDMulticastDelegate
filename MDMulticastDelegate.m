#import "MDMulticastDelegate.h"

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

/**
 * How does this class work?
 *
 * In theory, this class is very straight-forward.
 * It provides a way for multiple delegates to be called, each on its own delegate queue.
 *
 * In other words, any delegate method call to this class
 * will get forwarded (dispatch_async'd) to each added delegate.
 *
 * Important note concerning thread-safety:
 *
 * This class is designed to be used from within a single dispatch queue.
 * In other words, it is NOT thread-safe, and should only be used from within the external dedicated dispatch_queue.
 **/

@interface MDMulticastDelegate () {
    NSRecursiveLock *_lock;
    NSMapTable<id, NSMutableOrderedSet<dispatch_queue_t> *> *_delegates;
}

@end

@implementation MDMulticastDelegate

- (instancetype)init {
    if (self = [super init]) {
        _lock = [[NSRecursiveLock alloc] init];
        _delegates = [NSMapTable weakToStrongObjectsMapTable];
    }
    return self;
}

#pragma mark - private

- (void)_addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    NSMutableOrderedSet *queues = [_delegates objectForKey:delegate];
    if (!queues) {
        queues = [NSMutableOrderedSet orderedSet];
        [_delegates setObject:queues forKey:delegate];
    }

    [queues addObject:delegateQueue];
}

- (void)_removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    if (delegateQueue) {
        NSMutableOrderedSet *queues = [_delegates objectForKey:delegate];
        [queues removeObject:delegateQueue];

        if (!queues.count) {
            [_delegates removeObjectForKey:delegate];
        }
    } else {
        [_delegates removeObjectForKey:delegate];
    }
}

- (NSUInteger)_count {
    NSUInteger count = 0;
    for (id delegate in _delegates) {
        count += [_delegates objectForKey:delegate].count;
    }
    return count;
}

- (NSUInteger)_countOfDelegateBlock:(BOOL (^)(id delegate))block {
    if (!block) return 0;

    NSUInteger count = 0;
    for (id delegate in _delegates) {
        if (block(delegate)) {
            count += [_delegates objectForKey:delegate].count;
        }
    }
    return count;
}

- (BOOL)_hasDelegateThatRespondsToSelector:(SEL)aSelector {
    for (id delegate in _delegates) {
        if ([delegate respondsToSelector:aSelector]) return YES;
    }
    return NO;
}

- (void)_enumerateDelegatesAndQueuesUsingBlock:(void (NS_NOESCAPE ^)(id delegate, dispatch_queue_t delegateQueue, BOOL *stop))block {
    BOOL stop = NO;
    for (id delegate in _delegates) {
        for (dispatch_queue_t queue in [_delegates objectForKey:delegate]) {
            block(delegate, queue, &stop);

            if (stop) return;
        }
    }
}

- (void)_invokeWithDelegate:(id)delegate queue:(dispatch_queue_t)queue invocation:(NSInvocation *)invocation {
    // All delegates MUST be invoked ASYNCHRONOUSLY.
    NSInvocation *dupInvocation = [self _duplicateInvocation:invocation];

    dispatch_async(queue, ^{ @autoreleasepool {
        [dupInvocation invokeWithTarget:delegate];
    }});
}

- (void)_throwExceptionAtIndex:(NSUInteger)index type:(const char *)type selector:(SEL)selector {
    NSString *selectorStr = NSStringFromSelector(selector);

    NSString *format = @"Argument %lu to method %@ - Type(%c) not supported";
    NSString *reason = [NSString stringWithFormat:format, (unsigned long)(index - 2), selectorStr, *type];

    [[NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil] raise];
}

- (void)_copyStructValueAtIndex:(NSUInteger)index type:(const char *)type fromInvocation:(NSInvocation *)fromInvocation toInvocation:(NSInvocation *)toInvocation {
    NSUInteger size = 0;
    NSUInteger align = 0;
    NSGetSizeAndAlignment(type, &size, &align);

    void *buffer = malloc(size);

    [fromInvocation getArgument:buffer atIndex:index];
    [toInvocation setArgument:buffer atIndex:index];

    free(buffer);
}

- (void)_doNothing {}

- (NSInvocation *)_duplicateInvocation:(NSInvocation *)origInvocation {
    NSMethodSignature *methodSignature = [origInvocation methodSignature];

    NSInvocation *dupInvocation = [NSInvocation invocationWithMethodSignature:methodSignature];
    dupInvocation.selector = [origInvocation selector];

    NSUInteger i, count = [methodSignature numberOfArguments];
    for (i = 2; i < count; i++) {
        const char *type = [methodSignature getArgumentTypeAtIndex:i];
        switch (*type) {
                // void
            case 'v': break;
                // char
            case 'c':
                // unsigned char
            case 'C': {
                char value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // short
            case 's':
                // unsigned short
            case 'S': {
                short value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // int
            case 'i':
                // unsigned int
            case 'I': {
                int value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // long
            case 'l':
                // long
            case 'L': {
                long value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // long long
            case 'q':
                // unsigned long long
            case 'Q': {
                long long value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // float
            case 'f': {
                float value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // double
            case 'd': {
                double value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // long double
            case 'D': {
                long double value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // bool
            case 'B': {
                BOOL value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // selector
            case ':': {
                SEL value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // c string char *
            case '*':
                // OC object
            case '@':
                // pointer
            case '^': {
                void *value;
                [origInvocation getArgument:&value atIndex:i];
                [dupInvocation setArgument:&value atIndex:i];
            } break;
                // struct
            case '{': [self _copyStructValueAtIndex:i type:type fromInvocation:origInvocation toInvocation:dupInvocation]; break;
                // c array
            case '[':
                // c union
            case '(':
                // bitfield
            case 'b':
                // no type
            case 0:
            default: [self _throwExceptionAtIndex:i type:type selector:[origInvocation selector]]; break;
        }
    }
    [dupInvocation retainArguments];

    return dupInvocation;
}

#pragma mark - public

- (void)addDelegate:(id)delegate {
    [self addDelegate:delegate delegateQueue:dispatch_get_main_queue()];
}

- (void)addDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    if (!delegate) return;
    if (!delegateQueue) return;

    [_lock lock];
    [self _addDelegate:delegate delegateQueue:delegateQueue];
    [_lock unlock];
}

- (void)removeDelegate:(id)delegate delegateQueue:(dispatch_queue_t)delegateQueue {
    if (delegate == nil) return;

    [_lock lock];
    [self _removeDelegate:delegate delegateQueue:delegateQueue];
    [_lock unlock];
}

- (void)removeDelegate:(id)delegate {
    [self removeDelegate:delegate delegateQueue:nil];
}

- (void)removeAllDelegates {
    [_lock lock];
    [_delegates removeAllObjects];
    [_lock unlock];
}

- (NSUInteger)count {
    [_lock lock];
    NSUInteger count = [self _count];
    [_lock unlock];
    return count;
}

- (NSUInteger)countOfDelegates {
    [_lock lock];
    NSUInteger count = [_delegates count];
    [_lock unlock];
    return count;
}

- (NSUInteger)countOfClass:(Class)aClass {
    [_lock lock];
    NSUInteger count = [self _countOfDelegateBlock:^BOOL(id delegate) {
        return [delegate isKindOfClass:aClass];
    }];
    [_lock unlock];
    return count;
}

- (NSUInteger)countForSelector:(SEL)aSelector {
    [_lock lock];
    NSUInteger count = [self _countOfDelegateBlock:^BOOL(id delegate) {
        return [delegate respondsToSelector:aSelector];
    }];
    [_lock unlock];

    return count;
}

- (BOOL)hasDelegateThatRespondsToSelector:(SEL)aSelector {
    [_lock lock];
    BOOL responds = [self _hasDelegateThatRespondsToSelector:aSelector];
    [_lock unlock];
    return responds;
}

- (void)enumerateDelegatesAndQueuesUsingBlock:(void (NS_NOESCAPE ^)(id delegate, dispatch_queue_t delegateQueue, BOOL *stop))block {
    [_lock lock];
    [self _enumerateDelegatesAndQueuesUsingBlock:block];
    [_lock unlock];
}

#pragma mark - protected

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *result = nil;

    [_lock lock];
    for (id delegate in _delegates) {
        NSMethodSignature *result = [delegate methodSignatureForSelector:aSelector];

        if (result) break;
    }
    [_lock unlock];

    if (result) return result;

    // This causes a crash...
    // return [super methodSignatureForSelector:aSelector];

    // This also causes a crash...
    // return nil;
    return [[self class] instanceMethodSignatureForSelector:@selector(_doNothing)];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [_lock lock];

    SEL selector = [invocation selector];

    for (id delegate in _delegates) {
        if (![delegate respondsToSelector:selector]) continue;

        for (dispatch_queue_t queue in [_delegates objectForKey:delegate]) {
           [self _invokeWithDelegate:delegate queue:queue invocation:invocation];
        }
    }

    [_lock unlock];
}

- (void)doesNotRecognizeSelector:(SEL)aSelector {
    // Prevent NSInvalidArgumentException
}

- (void)dealloc {
    [self removeAllDelegates];
}

@end
