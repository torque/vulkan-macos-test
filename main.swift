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

    init(demo_ctx: OpaquePointer?) {
        let contentRect = NSRect(x: 0, y: 0, width: 50, height: 50);
        self.window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: true
        )
        let viewController = MainViewController(demo_ctx: demo_ctx)
        // viewController.view = MainView(frame: contentRect)
        self.window.contentViewController = viewController

        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("yeah ok")

        self.window.title = "word"
        self.window.makeKeyAndOrderFront(nil)
        self.window.makeMain()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class WindowDelegate: NSObject, NSWindowDelegate {

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
        print("load view")
        self.view = self._view
    }

    override func viewDidLoad() {
        print("loading")

        super.viewDidLoad()
        // self._view.resizeSubviews(withOldSize: NSSize(width: 720, height: 720))

        print("loaded")

        CVDisplayLinkCreateWithActiveCGDisplays(&self.link)
        CVDisplayLinkSetOutputHandler(self.link) {
            link, now, outputTime, flagsIn, flagsOut -> CVReturn in

            self._view.demo()
            return kCVReturnSuccess
        }

        CVDisplayLinkStart(self.link)
        print("linked")
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
        print("layering")
        let layer = CAMetalLayer()
        layer.drawsAsynchronously = true

        let viewScale = self.convertToBacking(CGSize(width: 1.0, height: 1.0))
        layer.contentsScale = min(viewScale.width, viewScale.height)
        layer.frame = self.bounds
        print("vs: \(viewScale), \(layer.contentsRect)")
        print("layered \(self.demo_ctx!), \(Unmanaged.passUnretained(layer).toOpaque()) \(self.bounds)")

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

// class MainWindow: NSWindow {

// }
