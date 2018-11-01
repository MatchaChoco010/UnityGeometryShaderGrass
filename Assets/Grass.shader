Shader "Grass"
{
  Properties
  {
    _Width ("Width", Range(0,1)) = 0.1
    _WidthRandomness ("Width Randomness", Range(0,1)) = 0.2
    _Height ("Height", Range(0,3)) = 1
    _HeightRandomness ("Height Randomness", Range(0,1)) = 0.2

    _WaveStrength ("Wave Strength", Range(0, 1)) = 0.1
    _WaveScale ("Wave Scale", float) = 1
    _WaveSpeedX ("Wave Speed X", float) = 15
    _WaveSpeedY ("Wave Speed Y", float) = 14

    [NoScaleOffset]
    _MainTex("MainTex", 2D) = "white" {}

    _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
  }
  SubShader
  {
    Cull Off

    CGINCLUDE

    #include "ClassicNoise2D.hlsl"

    struct appdata
    {
      float4 vertex : POSITION;
      float4 color : COLOR;
      uint id : SV_VertexID;
    };

    struct v2g
    {
      float4 pos : SV_POSITION;
      float4 color : COLOR;
      uint id : TEXCOORD0;
    };

    struct g2f
    {
      float4 pos : SV_POSITION;
      float2 uv : TEXCOORD0;
      float3 worldPos : TEXCOORD1;
      half3 sh : TEXCOORD2;
    };

    float _Width;
    float _WidthRandomness;
    float _Height;
    float _HeightRandomness;

    float _WaveStrength;
    float _WaveScale;
    float _WaveSpeedX;
    float _WaveSpeedY;

    float _Cutoff;

    sampler2D _MainTex;

    float rand(float2 f){
      return frac(sin(dot(f.xy ,float2(12.9898,78.233))) * 43758.5453);
    }

    v2g vert (appdata v)
    {
      v2g o;
      o.pos = mul(UNITY_MATRIX_M, v.vertex);
      o.id = v.id;
      o.color = v.color;
      return o;
    }

    [maxvertexcount(8)]
    void geom (point v2g v[1], inout TriangleStream<g2f> outStream)
    {
      g2f o;

      float3 pos = mul(UNITY_MATRIX_VP, v[0].pos);

      float width = _Width * (1 + (rand(v[0].id.xx) - 0.5) * _WidthRandomness);
      float height = _Height * (1 + (rand(v[0].id.xx) - 0.5) * _HeightRandomness);

      float4x4 rot = float4x4(
        cos(rand(v[0].id.xx)), 0, -sin(rand(v[0].id.xx)), 0,
        0, 1, 0, 0,
        sin(rand(v[0].id.xx)), 0, cos(rand(v[0].id.xx)), 0,
        0, 0, 0, 1
      );

      float r = v[0].color.r;

      float noiseX = cnoise((pos.xy + _Time.xx * _WaveSpeedX) * _WaveScale) * 2 - 1;
      float noiseY = cnoise((pos.xy + _Time.xx * _WaveSpeedY) * _WaveScale) * 2 - 1;
      float4 wave = float4(noiseX, noiseY, 0, 0) * _WaveStrength * r;

      float2 offset = float2(floor(rand(v[0].id.xx * 13) * 4) / 4, 0);


      o.pos = mul(
        UNITY_MATRIX_VP,
        v[0].pos + mul(rot, float4(-width / 2, 0, 0, 0)));
      o.uv = float2(0, 0) + offset;
      o.worldPos = o.pos;
      o.sh = 0;
      #if UNITY_SHOULD_SAMPLE_SH
        o.sh = ShadeSHPerVertex(float(0, 1, 0, 1), o.sh);
      #endif
      outStream.Append(o);

      o.pos = mul(
        UNITY_MATRIX_VP,
        v[0].pos + mul(rot, float4(width / 2, 0, 0, 0)));
      o.uv = float2(0.25, 0) + offset;
      o.worldPos = o.pos;
      outStream.Append(o);

      o.pos = mul(
        UNITY_MATRIX_VP,
        v[0].pos + mul(rot, float4(-width / 2, height * r, 0, 0)) + wave);
      o.uv = float2(0, r) + offset;
      o.worldPos = o.pos;
      outStream.Append(o);

      o.pos = mul(
        UNITY_MATRIX_VP,
        v[0].pos + mul(rot, float4(width / 2, height * r, 0, 0)) + wave);
      o.uv = float2(0.25, r) + offset;
      o.worldPos = o.pos;
      outStream.Append(o);

      outStream.RestartStrip();

      o.pos = mul(
        UNITY_MATRIX_VP,
        v[0].pos + mul(rot, float4(0, 0, -width / 2, 0)));
      o.uv = float2(0, 0) + offset;
      o.worldPos = o.pos;
      outStream.Append(o);

      o.pos = mul(
        UNITY_MATRIX_VP,
        v[0].pos + mul(rot, float4(0, 0, width / 2, 0)));
      o.uv = float2(0.25, 0) + offset;
      o.worldPos = o.pos;
      outStream.Append(o);

      o.pos = mul(
        UNITY_MATRIX_VP,
        v[0].pos + mul(rot, float4(0, height * r, -width / 2, 0)) + wave);
      o.uv = float2(0, r) + offset;
      o.worldPos = o.pos;
      outStream.Append(o);

      o.pos = mul(
        UNITY_MATRIX_VP,
        v[0].pos + mul(rot, float4(0, height * r, width / 2, 0)) + wave);
      o.uv = float2(0.25, r) + offset;
      o.worldPos = o.pos;
      outStream.Append(o);
    }
    ENDCG

    Pass
    {
      Tags {"LightMode"="ShadowCaster"}

      CGPROGRAM
      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag
      #pragma multi_compile_shadowcaster
      #include "UnityCG.cginc"

      float4 frag(g2f i) : SV_Target
      {
        fixed4 col = tex2D(_MainTex, i.uv);
        clip(col.a - _Cutoff);
        SHADOW_CASTER_FRAGMENT(i)
      }
      ENDCG
    }
    Pass
    {
      Tags { "LightMode" = "Deferred" }

      CGPROGRAM
      #pragma target 4.0
      #pragma vertex vert
      #pragma geometry geom
      #pragma fragment frag
      #pragma multi_compile_prepassfinal

      #include "UnityCG.cginc"
      #include "Lighting.cginc"
      #include "UnityPBSLighting.cginc"

      void frag (g2f i,
        out half4 outDiffuse        : SV_Target0,
        out half4 outSpecSmoothness : SV_Target1,
        out half4 outNormal         : SV_Target2,
        out half4 outEmission       : SV_Target3)
      {
        fixed4 color = tex2D(_MainTex, i.uv);
        clip(color.a - _Cutoff);

        float3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
        float3 worldNormal = float3(0, 1, 0);

        SurfaceOutputStandard o;
        UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o);
        o.Albedo = color;
        o.Emission = 0.0;
        o.Alpha = 0.0;
        o.Occlusion = 1.0;
        o.Normal = worldNormal;

        UnityGI gi;
        UNITY_INITIALIZE_OUTPUT(UnityGI, gi);
        gi.indirect.diffuse = 0;
        gi.indirect.specular = 0;
        gi.light.color = 0;
        gi.light.dir = half3(0, 1, 0);
        gi.light.ndotl = LambertTerm(o.Normal, gi.light.dir);

        UnityGIInput giInput;
        UNITY_INITIALIZE_OUTPUT(UnityGIInput, giInput);
        giInput.light = gi.light;
        giInput.worldPos = i.worldPos;
        giInput.worldViewDir = worldViewDir;
        giInput.atten = 1;
        #if UNITY_SHOULD_SAMPLE_SH
          giInput.ambient = i.sh;
        #else
          giInput.ambient.rgb = 0.0;
        #endif

        LightingStandard_GI(o, giInput, gi);

        outEmission = LightingStandard_Deferred(o, worldViewDir, gi, outDiffuse, outSpecSmoothness, outNormal);
      }
      ENDCG
    }
  }
}
