const positionData = new Float32Array([
  +0.00, +0.75, 0, +1,
  +0.75, -0.75, 0, +1,
  -0.75, -0.75, 0, +1
]);

const colorData = new Float32Array([
  1, 1, 1, 1,
  0, 1, 0, 1,
  0, 1, 1, 1,
]);

let gpu;
let commandQueue;
let renderPassDescriptor;
let renderPipelineState;
let bufferPosition;
let bufferColor;

export async function init() {

  // WebGPUをサポートしているか判定
  if (!('WebGPURenderingContext' in window)) {
    // WebGPUをサポートしていない場合は終了
    document.body.className = 'error';
    return;
  }

  // ビューを初期化
  initLayer();

  // Metalのセットアップ
  setupMetal();
  // バッファーを作成
  makeBuffers();
  // パイプラインを作成
  await makePipeline();
  // 描画
  draw();

  function initLayer() {
    // canvas 要素を取得
    const canvas = document.querySelector('canvas');
    const canvasSize = canvas.getBoundingClientRect();
    canvas.width = canvasSize.width * devicePixelRatio;
    canvas.height = canvasSize.height * devicePixelRatio;

    // WebGPUのコンテキストを取得
    gpu = canvas.getContext('webgpu');
  }

  function setupMetal() {
    // コマンドキューを作成
    commandQueue = gpu.createCommandQueue();

    // レンダーパスを作成
    renderPassDescriptor = new WebGPURenderPassDescriptor();
    // このRender Passが実行されるときの挙動を設定
    renderPassDescriptor.colorAttachments[0].loadAction = gpu.LoadActionClear;
    renderPassDescriptor.colorAttachments[0].storeAction = gpu.StoreActionStore;
    // 背景色は黒にする
    renderPassDescriptor.colorAttachments[0].clearColor = [0.0, 0.0, 0.0, 1.0];
  }

  async function makePipeline() {
    // Metalシェーダーファイルを読み込む
    const shaderString = await((await fetch('./Shader.metal')).text());

    // Metalのシェーダーを読み込む
    const library = gpu.createLibrary(shaderString);
    const funcVertex = library.functionWithName('myVertexShader');
    const funcFragment = library.functionWithName('myFragmentShader');

    // パイプラインを作成
    const pipelineDescriptor = new WebGPURenderPipelineDescriptor();
    pipelineDescriptor.vertexFunction = funcVertex;
    pipelineDescriptor.fragmentFunction = funcFragment;
    pipelineDescriptor.colorAttachments[0].pixelFormat = gpu.PixelFormatBGRA8Unorm;

    renderPipelineState = gpu.createRenderPipelineState(pipelineDescriptor);
  }

  function makeBuffers() {
    // バッファーを作成
    bufferPosition = gpu.createBuffer(positionData);
    bufferColor = gpu.createBuffer(colorData);
  }

  function draw() {
    // ドローアブルを取得
    const drawable = gpu.nextDrawable();
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture;

    // コマンドバッファを作成
    const commandBuffer = commandQueue.createCommandBuffer();

    // コマンドエンコーダーを作成
    const encoder = commandBuffer.createRenderCommandEncoderWithDescriptor(renderPassDescriptor);

    encoder.setRenderPipelineState(renderPipelineState);
    // バッファーを頂点シェーダーに送る
    encoder.setVertexBuffer(bufferPosition, 0, 0);
    encoder.setVertexBuffer(bufferColor, 0, 1);
    // 三角形を作成
    encoder.drawPrimitives(gpu.PrimitiveTypeTriangle, 0, 3);

    // エンコード完了
    encoder.endEncoding();
    // 表示するドローアブルを登録
    commandBuffer.presentDrawable(drawable);
    // コマンドバッファをコミット（エンキュー）
    commandBuffer.commit();
  }
}