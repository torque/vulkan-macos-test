import Cocoa

@_cdecl("swift_launch_app")
public func launch_app(demo_ctx: OpaquePointer?) {
    let app = NSApplication.shared
    let delegate = MainDelegate(demo_ctx: demo_ctx)
    app.delegate = delegate
    app.setActivationPolicy(.regular)

    app.run()
}

class MainDelegate: NSObject, NSApplicationDelegate {
    let window: NSWindow
    let windowDelegate: WindowDelegate

    init(demo_ctx: OpaquePointer?) {
        let contentRect = NSRect(x: 0, y: 0, width: 50, height: 50);
        self.window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: true
        )
        self.windowDelegate = WindowDelegate()

        let viewController = MainViewController(demo_ctx: demo_ctx)
        self.window.contentViewController = viewController
        self.window.delegate = self.windowDelegate

        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        self.window.title = "ＴＥＳＴ"
        self.window.center()
        self.window.setFrameOrigin(NSPoint(x: self.window.frame.origin.x, y: self.window.frame.origin.y - 100))
        self.window.makeKeyAndOrderFront(nil)
        self.window.makeMain()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {
    var windowFrame: NSRect? = nil

    func customWindowsToEnterFullScreen(for window: NSWindow) -> [NSWindow]? {
        // I don't know how to replicate the default reduced motion fullscreen
        // animation. It seems we would have to create a duplicate window
        // (the default animation crossfades the normal-sized window into a
        // fullscreen duplicate—they're both visible on the screen
        // simultaneously during the animation).
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return nil
        } else {
            return [window]
        }
    }

    func customWindowsToExitFullScreen(for window: NSWindow) -> [NSWindow]? {
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            return nil
        } else {
            return [window]
        }
    }

    func window(_ window: NSWindow, startCustomAnimationToEnterFullScreenWithDuration duration: TimeInterval) {
        self.windowFrame = window.frame
        window.styleMask.insert(.fullScreen)
        NSAnimationContext.runAnimationGroup() { context in
            context.duration = duration
            window.animator().setFrame(window.screen!.frame, display: true)
        }
    }

    func window(_ window: NSWindow, startCustomAnimationToExitFullScreenWithDuration duration: TimeInterval) {
        // this has to be done before removing the fullScreen style mask on some
        // monitor layouts, otherwise the window will teleport to the wrong
        // monitor. I'm not sure why this happens (it happens on the bottom
        // monitor if you have two vertically stacked monitors) but I'm
        // guessing it's due to a bad interaction with the menubar.
        window.setFrame(window.screen!.visibleFrame, display: true)
        window.styleMask.remove(.fullScreen)
        NSAnimationContext.runAnimationGroup() { context in
            context.duration = duration
            window.animator().setFrame(self.windowFrame!, display: true)
        }
    }

    func windowDidFailToEnterFullScreen(_ window: NSWindow) {
        print("whoops")
    }
}

class MainViewController: NSViewController {
    var link: CVDisplayLink!
    var _view: MainView

    init(demo_ctx: OpaquePointer?) {
        let contentRect = NSRect(x: 0, y: 0, width: 720, height: 720);
        self._view = MainView(frame: contentRect, demo_ctx: demo_ctx)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("no") }

    override func loadView() {
        self.view = self._view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        CVDisplayLinkCreateWithActiveCGDisplays(&self.link)
        CVDisplayLinkSetOutputHandler(self.link) {
            link, now, outputTime, flagsIn, flagsOut -> CVReturn in

            self._view.demo()
            return kCVReturnSuccess
        }

        CVDisplayLinkStart(self.link)
    }
}

class MainView: NSView {
    var counter: Double = 0.0
    var viewQueue: MTLCommandQueue?
    let demo_ctx: OpaquePointer?

    override var wantsUpdateLayer: Bool { return true }

    init(frame: NSRect, demo_ctx: OpaquePointer?) {
        self.demo_ctx = demo_ctx

        super.init(frame: frame)

        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .crossfade
    }

    required init?(coder: NSCoder) { fatalError("nope!") }

    override func makeBackingLayer() -> CALayer {
        let layer = CAMetalLayer()
        layer.drawsAsynchronously = true

        let viewScale = self.convertToBacking(CGSize(width: 1.0, height: 1.0))
        layer.contentsScale = min(viewScale.width, viewScale.height)
        layer.frame = self.bounds

        demo_setup(self.demo_ctx, Unmanaged.passUnretained(layer).toOpaque())

        return layer
    }

    func demo() {
        demo_redraw(self.demo_ctx)
    }

    func proof() {
        guard let drawable = (self.layer as? CAMetalLayer)?.nextDrawable() else {
            return
        }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear


        let reciprocating = (self.counter > 0.25) ? 0.5 - self.counter : self.counter

        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0, green: 0.1, blue: reciprocating, alpha: 1.0
        )

        self.counter += 0.005
        if self.counter > 0.5 {
            self.counter = 0
        }

        guard let commandBuffer = self.viewQueue!.makeCommandBuffer() else {
            return
        }

        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        commandEncoder!.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func layer(
        _ layer: CALayer,
        shouldInheritContentsScale newScale: CGFloat,
        from window: NSWindow
    ) -> Bool {
        print("relayer")

        if newScale == layer.contentsScale {
            return false
        }

        layer.contentsScale = newScale
        return true
    }
}
