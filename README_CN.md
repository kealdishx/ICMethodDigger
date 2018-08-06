# ICMethodDigger 

以简便的方式打印几乎所有的公有和私有方法，目前支持 arm64 架构的设备。

## 要求

- iOS 8.0+
- arm64 Device

## 安装

### Pod

```
pod 'ICMethodDigger'
```

### 手动安装

将 `Source` 目录下的所有文件拖拽到项目中，并且**将编译架构设置为 `arm64`**。

## Usage

#### 1. 在目标文件中导入 `ICMethodDigger.h`:

```Objectivec
#import "ICMethodDigger.h"
```

#### 2. 在你想要调用的地方调用 `icm_logMethod` 方法去打印日志:

```Objectivec
FOUNDATION_EXTERN void icm_logMethod(Class cls, ICConditionBlock condition, _Nullable ICBeforeBlock before, _Nullable ICAfterBlock after);
```

- ##### 打印目标类所有的方法

```Objectivec
icm_logMethod([ViewController class], ^BOOL(SEL sel) {
		NSLog(@"%@", NSStringFromSelector(sel));
		return NO;
	}, nil, nil);
```

- ##### 打印运行时类所执行的方法

```Objectivec
icm_logMethod([ViewController class], ^BOOL(SEL sel) {
		NSLog(@"%@", NSStringFromSelector(sel));
		return YES;
	}, nil, nil);
```

- ##### 打印方法执行的耗时时长

```Objectivec
icm_logMethod([UIViewController class], ^BOOL(SEL sel) {
		return YES;
	}, nil, ^(id target, SEL sel, NSArray *args, NSTimeInterval interval, id retValue) {
		NSLog(@"target:%@ sel:%@ interval: %f", target, NSStringFromSelector(sel), interval);
	});
```

#### 3. 将 `arm64` 架构的手机连接到你的项目中，然后编译运行。

## 贡献

欢迎提 issue 和 PR。

## 致谢

- [ANYMethodLog](https://github.com/qhd/ANYMethodLog)
- [MainThreadChecker](https://github.com/SatanWoo/MainThreadChecker)

## 许可证

ICMethodDigger 遵循 MIT 许可证， 查看 LICENSE 文件获取更多信息。
