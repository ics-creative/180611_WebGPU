import Cocoa
import MetalKit

class ViewController: NSViewController {

    private let device = MTLCreateSystemDefaultDevice()!
    
    private let positionData: [Float] = [
        +0.00, +0.75, 0, +1,
        +0.75, -0.75, 0, +1,
        -0.75, -0.75, 0, +1
    ]
    
    private let colorData: [Float] = [
        1, 1, 1, 1,
        0, 1, 0, 1,
        0, 1, 1, 1,
    ]
    
    private var commandQueue: MTLCommandQueue!
    private var renderPassDescriptor: MTLRenderPassDescriptor!
    private var bufferPosition: MTLBuffer!
    private var bufferColor: MTLBuffer!
    private var renderPipeline: MTLRenderPipelineState!
    private var metalLayer: CAMetalLayer!;
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 960, height: 540))
        view.layer = CALayer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ビューを初期化
        initLayer();
        
        // Metalのセットアップ
        setupMetal()
        // バッファーを作成
        makeBuffers()
        // パイプラインを作成
        makePipeline()
        // 描画
        draw();
    }
    
    private func initLayer(){
        // レイヤーを作成
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer!.frame
        view.layer!.addSublayer(metalLayer)
    }
    
    private func setupMetal() {
        // MTLCommandQueueを初期化
        commandQueue = device.makeCommandQueue()
        
        renderPassDescriptor = MTLRenderPassDescriptor()
        // このRender Passが実行されるときの挙動を設定
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreAction.store
        // 背景色は黒にする
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0)
    }
    
    private func makeBuffers() {
        let size = positionData.count * MemoryLayout<Float>.size
        // 位置情報のバッファーを作成
        bufferPosition = device.makeBuffer(bytes: positionData, length: size)
        // 色情報のバッファーを作成
        bufferColor = device.makeBuffer(bytes: colorData, length: size)
    }
    
    private func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "myVertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "myFragmentShader")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipeline = try! device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    func draw() {
        // ドローアブルを取得
        guard let drawable = metalLayer.nextDrawable() else {fatalError()}
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        
        // コマンドバッファを作成
        guard let cBuffer = commandQueue.makeCommandBuffer() else {fatalError()}
        
        // エンコーダ生成
        let encoder = cBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor
        )!
        
        guard let renderPipeline = renderPipeline else {fatalError()}
        encoder.setRenderPipelineState(renderPipeline)
        // バッファーを頂点シェーダーに送る
        encoder.setVertexBuffer(bufferPosition, offset: 0, index: 0)
        encoder.setVertexBuffer(bufferColor, offset: 0, index:1)
        // 三角形を作成
        encoder.drawPrimitives(type: MTLPrimitiveType.triangle,
                               vertexStart: 0,
                               vertexCount: 3)
       
        // エンコード完了
        encoder.endEncoding()
        // 表示するドローアブルを登録
        cBuffer.present(drawable)
        // コマンドバッファをコミット（エンキュー）
        cBuffer.commit()
    }
}
