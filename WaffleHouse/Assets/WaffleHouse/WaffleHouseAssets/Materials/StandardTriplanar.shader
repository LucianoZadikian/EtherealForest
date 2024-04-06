// Standard shader with triplanar mapping
// https://github.com/keijiro/StandardTriplanar

Shader "Standard Triplanar"
{
    Properties
    {
        
        _ShadowIntensity("Shadow Intensity", Range(0,1)) = 0.4
        _ShadowFalloff("Shadow Falloff", Range(0,1)) = 0.005
        _Color("Tint", Color) = (1, 1, 1, 1)
        _Ramp("Ramp", 2D) = "white" {}
        _TexScale("Global Tiling", Float) = 1
        _MainTex("Color Map", 2D) = "white" {}
        _Bias("Color Map Bias", Range(-1, 1)) = 0 
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        CGPROGRAM

        #pragma surface surf Ramp vertex:vert //fullforwardshadows addshadow

        #pragma shader_feature _NORMALMAP
        #pragma shader_feature _OCCLUSIONMAP

        #pragma target 3.0

        float4 _Color;
        float _ShadowIntensity;
        float _ShadowFalloff;
        sampler2D _MainTex;
        float _Bias;

        float _Glossiness;

        float _TexScale;
        sampler2D _Ramp;

        float4 LightingRamp (SurfaceOutput s, float3 lightDir, float atten) {
            float NdotL = dot (s.Normal, lightDir);
            
            //float diff = NdotL * 0.5 + 0.5;
            //float3 ramp = tex2D (_Ramp, float2(diff.rr)).rgb;

            float lightFalloff = max(smoothstep(0, _ShadowFalloff, NdotL), _ShadowIntensity); 
            // float lightFalloff = NdotL > 0 ? 1 : 0; 
            float4 c;
            c.rgb = s.Albedo * _LightColor0.rgb * lightFalloff * atten;
            c.a = s.Alpha;
            return c;
        }
        
        struct Input
        {
            float4 position;
            float3 worldNormal;
        };

        struct TriplanarUV
        {
            float2 x, y, z;
        };

        TriplanarUV GetTriplanarUV(float4 pos, float tiling)
        {
            TriplanarUV triUV;
            float3 p = pos;
            triUV.x = p.zy * tiling;
            triUV.y = p.xz * tiling;
            triUV.z = p.xy * tiling;
            return triUV;
        }

        float4 TriplanarTextureSample(sampler2D tex, TriplanarUV triUV, float3 bf)
        {
            float4 cx = tex2D(tex, triUV.x) * bf.x;
            float4 cy = tex2D(tex, triUV.y) * bf.y;
            float4 cz = tex2D(tex, triUV.z) * bf.z;
            return (cx + cy + cz);
        }

        float GetTexHeightAlpha(float4 tex, float mask)
        {
            float heightLerp = clamp((tex.a - 1) + ((1 - mask) * 2), 0, 1);
            float step1 = smoothstep(0.25, 0.26, heightLerp);
            float step2 = smoothstep(0.0, 0.01, heightLerp);
            return saturate(step1 + step2 * 0.5);
        }
        
        void vert(inout appdata_full v, out Input data)
        {
            UNITY_INITIALIZE_OUTPUT(Input, data);
            data.position = v.vertex;
            data.worldNormal = UnityObjectToWorldNormal(v.normal.xyz);
        }

        

        void surf(Input IN, inout SurfaceOutput o)
        {
            _TexScale /= 100;
            
            // Blending factor of triplanar mapping
            float3 bf = normalize(abs(IN.worldNormal));
            bf /= (bf.x + bf.y + bf.z);

            TriplanarUV triUVSmall = GetTriplanarUV(IN.position, _TexScale);
            TriplanarUV triUVLarge = GetTriplanarUV(IN.position, _TexScale/7);

            
            float4 tex1Small = TriplanarTextureSample(_MainTex, triUVSmall, bf);
            float4 tex1Large = TriplanarTextureSample(_MainTex, triUVLarge, bf);
            float4 tex1 = lerp(tex1Small, tex1Large, 0.5);
            tex1.a = tex1.a - _Bias;
            float tex1Blend = GetTexHeightAlpha(tex1, IN.worldNormal.y);

            


            o.Albedo = lerp(tex1.rgb, 0, tex1Blend);
            o.Alpha = 1;

            // #ifdef _NORMALMAP
            //     // Normal map
            //     float4 nx = tex2D(_BumpMap, tx) * bf.x;
            //     float4 ny = tex2D(_BumpMap, ty) * bf.y;
            //     float4 nz = tex2D(_BumpMap, tz) * bf.z;
            //     o.Normal = UnpackScaleNormal(nx + ny + nz, _BumpScale);
            // #endif
        }
        
        ENDCG
    }
    FallBack "Diffuse"
    CustomEditor "StandardTriplanarInspector"
}
