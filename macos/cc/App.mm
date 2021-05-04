/*
* Copyright 2019 Google Inc.
*
* Use of this source code is governed by a BSD-style license that can be
* found in the LICENSE file.
*/

#import <Cocoa/Cocoa.h>
#include <jni.h>
#include "impl/Library.hh"
#include "Window.hh"

@interface AppDelegate : NSObject<NSApplicationDelegate, NSWindowDelegate>

@property (nonatomic, assign) BOOL done;

@end

@implementation AppDelegate : NSObject

@synthesize done = _done;

- (id)init {
    self = [super init];
    _done = FALSE;
    return self;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    _done = TRUE;
    return NSTerminateCancel;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp stop:nil];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////

extern "C" JNIEXPORT void JNICALL Java_org_jetbrains_jwm_App_init
  (JNIEnv* env, jclass jclass) {
#if MAC_OS_X_VERSION_MAX_ALLOWED < 1070
    // we only run on systems that support at least Core Profile 3.2
    return EXIT_FAILURE;
#endif
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    [NSApplication sharedApplication];

    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

    //Create the application menu.
    NSMenu* menuBar=[[NSMenu alloc] initWithTitle:@"AMainMenu"];
    [NSApp setMainMenu:menuBar];

    NSMenuItem* item;
    NSMenu* subMenu;

    item=[[NSMenuItem alloc] initWithTitle:@"Apple" action:nil keyEquivalent:@""];
    [menuBar addItem:item];
    subMenu=[[NSMenu alloc] initWithTitle:@"Apple"];
    [menuBar setSubmenu:subMenu forItem:item];
    [item release];
    item=[[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    [subMenu addItem:item];
    [item release];
    [subMenu release];
    [menuBar release];
    [pool release];
}

extern "C" JNIEXPORT jint JNICALL Java_org_jetbrains_jwm_App_runEventLoop
  (JNIEnv* env, jclass jclass, jobject eventConsumer) {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    // Set AppDelegate to catch certain global events
    AppDelegate* appDelegate = [[AppDelegate alloc] init];
    [NSApp setDelegate:appDelegate];

    // Application* app = Application::Create(argc, argv, nullptr);

    // This will run until the application finishes launching, then lets us take over
    [NSApp run];

    // Now we process the events
    while (![appDelegate done]) {
        NSEvent* event;
        do {
            event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                       untilDate:[NSDate distantPast]
                                          inMode:NSDefaultRunLoopMode
                                         dequeue:YES];
            [NSApp sendEvent:event];
        } while (event != nil);

        [pool drain];
        pool = [[NSAutoreleasePool alloc] init];

        // Rather than depending on a Mac event to drive this, we treat our window
        // invalidation flag as a separate event stream. Window::onPaint() will clear
        // the invalidation flag, effectively removing it from the stream.
        // Window_mac::PaintWindows();

        jwm::AutoLocal<jobject> eventPaint(env, jwm::classes::PaintEvent::make(env));
        jwm::classes::Consumer::accept(env, eventConsumer, eventPaint.get());

        // app->onIdle();
    }

    // delete app;

    [NSApp setDelegate:nil];
    [appDelegate release];

    // [menuBar release];
    [pool release];

    return EXIT_SUCCESS;
}

extern "C" JNIEXPORT void JNICALL Java_org_jetbrains_jwm_App_terminate
  (JNIEnv* env, jclass jclass) {
    [NSApp terminate:nil];
}