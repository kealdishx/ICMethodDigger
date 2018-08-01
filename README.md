# ICMethodDigger

An easy way to print almost methods including private methods (supported arm64 architecture devices).

## Requirements

- iOS 8.0+
- arm64 Device

## Installation

### Manually

Drag all files under `Source` folder to your project, and **set build architecture to `arm64`**.

## Usage

1. import `ICMethodDigger.h` to your target file like this:

```Objectivec
#import "ICMethodDigger.h"
```

2. call `icm_logMethod` method to log what you want:

```Objectivec
FOUNDATION_EXTERN void icm_logMethod(Class cls, ICConditionBlock condition, _Nullable ICBeforeBlock before, _Nullable ICAfterBlock after);
```

- 1) log all methods of target class

```Objectivec
icm_logMethod([ViewController class], ^BOOL(SEL sel) {
		NSLog(@"%@", NSStringFromSelector(sel));
		return NO;
	}, nil, nil);
```

- 2) log methods at running

```Objectivec
icm_logMethod([ViewController class], ^BOOL(SEL sel) {
		NSLog(@"%@", NSStringFromSelector(sel));
		return YES;
	}, nil, nil);
```

- 3) log cost time of method

```Objectivec
icm_logMethod([UIViewController class], ^BOOL(SEL sel) {
		return YES;
	}, nil, ^(id target, SEL sel, NSArray *args, NSTimeInterval interval, id retValue) {
		NSLog(@"target:%@ sel:%@ interval: %f", target, NSStringFromSelector(sel), interval);
	});
```

## Contributing

Issues and pull requests are welcome!

## Acknowledgements

- [ANYMethodLog](https://github.com/qhd/ANYMethodLog)
- [MainThreadChecker](https://github.com/SatanWoo/MainThreadChecker)

## LICENSE

ICMethodDigger is available under the MIT license. See the LICENSE file for more info.
