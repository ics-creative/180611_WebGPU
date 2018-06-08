#include <metal_stdlib>

using namespace metal;

// 構造体を定義
struct MyVertex {
    // 座標
    float4 position [[position]];
    // 色
    float4 color;
};

// 頂点シェーダー
vertex MyVertex myVertexShader(device float4 *position [[ buffer(0) ]],
                               device float4 *color [[ buffer(1) ]],
                               uint vid [[vertex_id]]) {
    MyVertex v;
    // 0番目のバッファーから頂点座標を設定
    v.position = position[vid];
    // 1番目のバッファーから頂点に色を設定
    v.color = color[vid];
    return v;
}

// 断片シェーダー
fragment float4 myFragmentShader(MyVertex vertexIn [[stage_in]]) {
    // 塗りの色を指定
    return vertexIn.color;
}
