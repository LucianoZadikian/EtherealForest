Shader "RoR2 Triplanar"
{
    Properties
    {
        // Global Properties
        [Header(Global Settings)] _Color("Color", Color) = (1, 1, 1, 1)
        _ShadowIntensity("Shadow Intensity", Range(0,1)) = 0.4
        _ShadowFalloff("Shadow Falloff", Range(0,1)) = 0.005
        _TexScale("Global Tiling", Range(0, 1)) = 1
        _NormalMap("Normal Map", 2D) = "white" {}
        _NormalIntesity("Normal Intensity", Range(0, 1)) = 1
        _SplatMap("Splat Map", 2D) = "black" {}

         // Properties for Main Texture
        [Space(20)] [Header(Main Texture Settings)]_Tex1("Main Texture", 2D) = "gray"{}
        [Toggle]_Tex1MultColor("Multiply by Color?", Float) = 0
        
         // Properties for Texture 2 
        [Space(20)] [Header(Texture 2 Settings)]_Tex2("Texture 2", 2D) = "gray"{}
        _Tex2Bias("Texture 2 Bias", Range(-1, 1)) = 0
        [Toggle]_Tex2MultColor("Multiply by Color?", Float) = 0
        [Toggle]_Tex2InvertMask("Invert mask?", Float) = 0
        _Tex2Contrast("Texture 2 Contrast", Range(0, 1)) = 0
        [KeywordEnum(None, Red, Green, Blue, Alpha)] _Tex2SplatChannel("Texture 2 Splatmap Channel", Float) = 0
        [KeywordEnum(None, X, Y, Z)] _Tex2NormalChannel("Texture 2 Slope Channel", Float) = 0
        [KeywordEnum(None, Red, Green, Blue, Alpha)] _Tex2VertexColorChannel("Texture 2 Vertex Color Channel", Float) = 0
        
        // Properties for Texture 3 
        [Space(20)] [Header(Texture 3 Settings)]_Tex3("Texture 3", 2D) = "gray"{}
        _Tex3Bias("Texture 3 Bias", Range(0, 1)) = 0
        [Toggle]_Tex3MultColor("Multiply by Color?", Float) = 0
        [Toggle]_Tex3InvertMask("Invert mask?", Float) = 0
        _Tex3Contrast("Texture 3 Contrast", Range(0, 1)) = 0
        [KeywordEnum(None, Red, Green, Blue, Alpha)] _Tex3SplatChannel("Texture 3 Splatmap Channel", Float) = 0
        [KeywordEnum(None, X, Y, Z)] _Tex3NormalChannel("Texture 3 Slope Channel", Float) = 0
        [KeywordEnum(None, Red, Green, Blue, Alpha)] _Tex3VertexColorChannel("Texture 3 Vertex Color Channel", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }

        CGPROGRAM
        #pragma surface surf Ramp vertex:vert //fullforwardshadows addshadow

        #pragma shader_feature _NORMALMAP
        #pragma shader_feature _OCCLUSIONMAP

        #pragma target 3.5

        // Global Properties
        float4 _Color;
        float _ShadowIntensity;
        float _ShadowFalloff;
        float _TexScale;
        sampler2D _NormalMap;
        float4 _NormalMap_ST;
        float _NormalIntesity;
        sampler2D _SplatMap;
        float4 _SplatMap_ST;
        

        // Properties for Main Texture
        sampler2D _Tex1;
        float4 _Tex1_ST;
        float _Tex1Bias;
        float _Tex1Contrast;
        float _Tex1MultColor;
        float _Tex1InvertMask;
        float _Tex1SplatChannel;
        float _Tex1NormalChannel;
        float _Tex1VertexColorChannel;

        // Properties for Texture 2 
        sampler2D _Tex2;
        float4 _Tex2_ST;
        float _Tex2Bias;
        float _Tex2Contrast;
        float _Tex2MultColor;
        float _Tex2InvertMask;
        float _Tex2SplatChannel;
        float _Tex2NormalChannel;
        float _Tex2VertexColorChannel;

        // Properties for Texture 3
        sampler2D _Tex3;
        float4 _Tex3_ST;
        float _Tex3Bias;
        float _Tex3Contrast;
        float _Tex3MultColor;
        float _Tex3InvertMask;
        float _Tex3SplatChannel;
        float _Tex3NormalChannel;
        float _Tex3VertexColorChannel;

        
        struct Input
        {
            float4 position;
            float3 normal;
            float2 texCoord;
            float4 vertexColor;
        };

        struct TextureProperties
        {
            sampler2D tex;
            float4 ST;
            float bias;
            float contrast;
            float multiplyByColor;
            float invertMask;
            float splatChannelProperty;
            float normalChannelProperty;
            float vertexColorChannelProperty;
        };

        // Controls the main lighting
        // TODO:
        // - Implement smoothness param for glossy surfaces
        // - Modulate value of shadows by _ShadowIntensity 
        float4 LightingRamp(SurfaceOutput s, float3 lightDir, float3 viewDir, float atten)
        {
            float NdotL = dot(s.Normal, lightDir);
            float lightFalloff = max(smoothstep(0, _ShadowFalloff, NdotL), 1 - _ShadowIntensity);
            return float4((s.Albedo * _LightColor0.rgb * lightFalloff) * atten, s.Alpha);
        }
        
        struct TriplanarUV
        {
            float2 x, y, z;
        };

        TriplanarUV GetTriplanarUV(float4 pos, float2 tiling)
        {
            TriplanarUV triUV;
            float3 p = pos;
            triUV.x = p.zy * tiling * _TexScale;
            triUV.y = p.xz * tiling * _TexScale;
            triUV.z = p.xy * tiling * _TexScale;
            return triUV;
        }

        float4 TriplanarTextureSample(sampler2D tex, TriplanarUV triUV, float3 bf)
        {
            float4 cx = tex2D(tex, triUV.x) * bf.x;
            float4 cy = tex2D(tex, triUV.y) * bf.y;
            float4 cz = tex2D(tex, triUV.z) * bf.z;
            return (cx + cy + cz);
        }

        float GetTexHeightAlpha(float4 tex, float mask, float bias, float contrast)
        {
            float heightLerp = 1 - ((1 - tex.a) * (1 - mask));
            heightLerp = saturate(heightLerp);
            heightLerp = smoothstep(bias, bias + (1 - contrast), heightLerp);
            
            float step1 = smoothstep(0.5,0.52, heightLerp);// top 
            float step2 = smoothstep(0.15, 0.17, heightLerp);// middle 
            float step3 = smoothstep(0.1, 0.12,  heightLerp);// bottom

            return saturate(step1 * 0.4 + step2 * 0.35 + step3 * 0.25); // darken alphas for blending
        }

        float GetMaskFromTexByEnum(float inputEnum, sampler2D tex, float2 uv)
        {
            switch (inputEnum)
            {
                case 1:
                    return tex2D(tex, uv).r;
                case 2:
                    return tex2D(tex, uv).g;
                case 3:
                    return tex2D(tex, uv).b;
                case 4:
                    return tex2D(tex, uv).a;
                default:
                    return 0;
            }
        }

        float GetMaskFromDataByEnum(float inputEnum, float4 data)
        {
            switch (inputEnum)
            {
                case 1:
                    return data.r;
                case 2:
                    return data.g;
                case 3:
                    return data.b;
                case 4:
                    return data.a;
                default:
                    return 0;
            }
        }

        // Mega function for sampling textures, should use for anything that we want to layer.
        // bf - Blend Factor, controls the "contrast" of our triplanar projections.
        float4 BuildTerrainTexture(TextureProperties tex, Input IN, float3 bf)
        {
            TriplanarUV triUVSmall = GetTriplanarUV(IN.position, _TexScale * tex.ST.xy);
            TriplanarUV triUVLarge = GetTriplanarUV(IN.position, (_TexScale * tex.ST.xy) * 0.2); 
            
            float4 tex_small = TriplanarTextureSample(tex.tex, triUVSmall, bf);
            float4 tex_large = TriplanarTextureSample(tex.tex,  triUVLarge, bf);
            float4 tex_combined = lerp(tex_small, tex_large, 0.5);
            float tex_splatMask = GetMaskFromTexByEnum(tex.splatChannelProperty, _SplatMap, IN.texCoord);
            float tex_slopeMask = GetMaskFromDataByEnum(tex.normalChannelProperty, float4(IN.normal, 0));
            float tex_colorMask = GetMaskFromDataByEnum(tex.vertexColorChannelProperty, IN.vertexColor);
            float tex_Mask = saturate(tex_splatMask + tex_slopeMask + tex_colorMask * tex_combined.a);
            float tex_blend = GetTexHeightAlpha(tex_small, tex_Mask, tex.bias, tex.contrast);
            float tex_blend2 = GetTexHeightAlpha(tex_large, tex_Mask, tex.bias, tex.contrast);
            float tex_blendCombined = lerp(tex_blend, tex_blend2, 0.5);
            
            if(tex.invertMask)
            {
                tex_blendCombined = 1-tex_blendCombined;
            }
            return float4(tex.multiplyByColor > 0.0 ? tex_combined.rgb * _Color : tex_combined.rgb, tex_blendCombined); // if color multiply true
        }
        
        TextureProperties BuildTextureProperties(sampler2D tex, float4 ST, float bias, float contrast, float multColor, float invertMask, float splatChannel, float normalChannel, float vertexColorChannel)
        {
            TextureProperties texProperties;
            texProperties.tex = tex;
            texProperties.ST = ST;
            texProperties.bias = bias;
            texProperties.contrast = contrast;
            texProperties.multiplyByColor = multColor;
            texProperties.invertMask = invertMask;
            texProperties.splatChannelProperty = splatChannel;
            texProperties.normalChannelProperty = normalChannel;
            texProperties.vertexColorChannelProperty = vertexColorChannel;
            return texProperties;
        }
        
        void vert(inout appdata_full v, out Input data)
        {
            UNITY_INITIALIZE_OUTPUT(Input, data);
            data.position = v.vertex;
            data.normal = UnityObjectToWorldNormal(v.normal.xyz);
            data.vertexColor = v.color;
        }

        void surf(Input IN, inout SurfaceOutput o)
        {
            _TexScale /= 1; // divided for usability

            // Blending factor of triplanar mapping, controls the "contrast" of our triplanar projections.
            float3 bf = normalize(abs(IN.normal) * abs(IN.normal));
            bf /= (bf.x + bf.y + bf.z);

            // Build Albedo
            TextureProperties tex1Properties = BuildTextureProperties(_Tex1, _Tex1_ST, _Tex1Bias, _Tex1Contrast, _Tex1MultColor, _Tex1InvertMask, _Tex1SplatChannel, _Tex1NormalChannel, _Tex1VertexColorChannel);
            TextureProperties tex2Properties = BuildTextureProperties(_Tex2, _Tex2_ST, _Tex2Bias, _Tex2Contrast, _Tex2MultColor, _Tex2InvertMask, _Tex2SplatChannel, _Tex2NormalChannel, _Tex2VertexColorChannel);
            TextureProperties tex3Properties = BuildTextureProperties(_Tex3, _Tex3_ST, _Tex3Bias, _Tex3Contrast, _Tex3MultColor, _Tex3InvertMask, _Tex3SplatChannel, _Tex3NormalChannel, _Tex3VertexColorChannel);

            float4 tex1 = BuildTerrainTexture(tex1Properties, IN, bf);
            float4 tex2 = BuildTerrainTexture(tex2Properties, IN, bf);
            float4 tex3 = BuildTerrainTexture(tex3Properties, IN, bf);


            float3 blend1 = lerp(tex1.rgb, tex2.rgb, tex2.a);
            float3 blend2 = lerp(blend1.rgb, tex3.rgb, tex3.a);
            
            o.Albedo = blend2;
            
            // Build normal 
            TriplanarUV triUVNormal = GetTriplanarUV(IN.position, (_TexScale * _NormalMap_ST.xy) * 0.2);
            
            o.Normal = UnpackNormalWithScale(TriplanarTextureSample(_NormalMap, triUVNormal, bf), _NormalIntesity);
        }
        ENDCG
    }
    FallBack "Diffuse"
    CustomEditor "StandardTriplanarInspector"
}