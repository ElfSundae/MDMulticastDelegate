# MDMulticastDelegate

`MDMulticastDelegate` provides thread-safe multicast delegate functionality, it is inspired by the [`GCDMulticastDelegate`](https://github.com/robbiehanson/XMPPFramework/blob/master/Utilities/GCDMulticastDelegate.h) from [XMPPFramework](https://github.com/robbiehanson/XMPPFramework).

## Installation

```ruby
pod 'MDMulticastDelegate'
```

## Usage

### Create MDMulticastDelegate instance

```objc
@property (nonatomic, strong) MDMulticastDelegate<FooProtocol> *delegates;

self.delegates = [MDMulticastDelegate<FooProtocol> new];
```

### Add delegate objects

```objc
// The delegate methods will be invoked on the main dispatch queue.
[self.delegates addDelegate:obj];

// The delegate methods will be invoked on the taskQueue.
[self.delegates addDelegate:obj1 delegateQueue:taskQueue];
```

### Remove delegate objects

:warning: MDMulticastDelegate stores delegate objects with weak references, therefore you do not need to remove delegate objects in their `-dealloc` methods.

```objc
[self.delegates removeDelegate:obj];

[self.delegates removeDelegate:obj1 delegateQueue:someQueue];

[self.delegates removeAllDelegates];
```

### Invoke delegate methods

```objc
[self.delegates fooMethod];
```

### Enumerate delegate objects

```objc
[self.delegates enumerateDelegatesAndQueuesUsingBlock:
    ^(id<FooProtocol> delegate, dispatch_queue_t delegateQueue, BOOL *stop) {
        //
    }
];
```
