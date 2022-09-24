import Cocoa

@_cdecl("swift_launch_app")
public func launch_app() {
    let app = NSApplication.shared
    let delegate = MainDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)

    app.run()
}

class MainDelegate: NSObject, NSApplicationDelegate {
    let window: NSWindow

    override init() {
        let contentRect = NSRect(x: 0, y: 0, width: 50, height: 50);
        self.window = NSWindow.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: true
        )
        let viewController = MainViewController()
        // viewController.view = MainView(frame: contentRect)
        self.window.contentViewController = viewController

        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("yeah ok")
        print_int(5)

        self.window.title = "word"
        self.window.makeKeyAndOrderFront(nil)
        self.window.makeMain()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

class MainViewController: NSViewController {
    var link: CVDisplayLink?

    override func loadView() {
        print("load view")
        let contentRect = NSRect(x: 0, y: 0, width: 720, height: 720);
        self.view = MainView(frame: contentRect)
    }

    override func viewDidLoad() {
        print("loading")

        super.viewDidLoad()

        print("loaded")
        CVDisplayLinkCreateWithActiveCGDisplays(&self.link)
        CVDisplayLinkSetOutputCallback(
            self.link!,
            update_display,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self.view).toOpaque())
        )

        CVDisplayLinkStart(self.link!)
        print("linked")
    }
}

func update_display(
    link: CVDisplayLink,
    now: UnsafePointer<CVTimeStamp>,
    outputTime: UnsafePointer<CVTimeStamp>,
    flagsIn: CVOptionFlags,
    flagsOut: UnsafeMutablePointer<CVOptionFlags>,
    target: UnsafeMutableRawPointer?
) -> CVReturn {
    let view = unsafeBitCast(target, to: MainView.self)
    view.proof()

    return kCVReturnSuccess;
}

class MainView: NSView {
    var counter: Double = 0.0
    var viewQueue: MTLCommandQueue?

    override var wantsLayer: Bool { get {return true} set(new) {} }
    override var wantsUpdateLayer: Bool { return true }

    override func makeBackingLayer() -> CALayer {
        print("layering")
        let layer = CAMetalLayer()

        layer.isOpaque = false
        layer.device = MTLCreateSystemDefaultDevice()
        layer.drawsAsynchronously = true

        let viewScale = self.convertToBacking(CGSize(width: 1.0, height: 1.0))
        layer.contentsScale = min(viewScale.width, viewScale.height)

        print("deviced")
        self.viewQueue = layer.device!.makeCommandQueue()
        print("queue")

        print("layered")
        return layer
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
