// iOS 27+ requires apps built with the new SDK to adopt the UIScene lifecycle, otherwise they
// are killed at launch. Godot 4.4 still uses the old app lifecycle, so this scene delegate
// adopts the scene and hands Godot's own window (created by its app delegate) to it, and
// forwards the scene's activity events to the app delegate, where Godot listens for them.
#import <UIKit/UIKit.h>

@interface GodotSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@implementation GodotSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
	if (![scene isKindOfClass:[UIWindowScene class]]) {
		return;
	}
	UIWindowScene *windowScene = (UIWindowScene *)scene;
	id<UIApplicationDelegate> app = UIApplication.sharedApplication.delegate;
	UIWindow *w = [app respondsToSelector:@selector(window)] ? app.window : nil;
	if (w) {
		w.windowScene = windowScene;
		w.frame = windowScene.coordinateSpace.bounds;
		self.window = w;
		[w makeKeyAndVisible];
	}
}

static void forward(SEL sel) {
	UIApplication *a = UIApplication.sharedApplication;
	id<UIApplicationDelegate> d = a.delegate;
	if ([d respondsToSelector:sel]) {
		((void (*)(id, SEL, UIApplication *))[(NSObject *)d methodForSelector:sel])(d, sel, a);
	}
}

- (void)sceneDidBecomeActive:(UIScene *)scene { forward(@selector(applicationDidBecomeActive:)); }
- (void)sceneWillResignActive:(UIScene *)scene { forward(@selector(applicationWillResignActive:)); }
- (void)sceneDidEnterBackground:(UIScene *)scene { forward(@selector(applicationDidEnterBackground:)); }
- (void)sceneWillEnterForeground:(UIScene *)scene { forward(@selector(applicationWillEnterForeground:)); }

@end

// called by Godot (from C++) at start-up; also makes the linker keep this file
void scene_lifecycle_init(void) {}
void scene_lifecycle_deinit(void) {}
