Shader "Custom/1"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		
		_HeightMap ("HeightMap", 2D) = "white"{}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		_HeightMultiplier ("HeightMultiplier", Range(0,100)) = 0.0
		_SampleMultiplier ("SampleMultiplier", Range(0,1024)) = 10.0
		
		_VertexMin("VertexMin", Vector) = (-5,-5,-5,-5)
		_VertexMax("VertexMax", Vector) = (5,5,5,5)
		_UVMin ("UVMin ", Vector) = (0,0,0,0)
		_UVMax ("UVMax ", Vector) = (1,1,1,1)

		_CropSize ("CropSize",Vector) = (0,0,0,0)
		_CropOffset ("CropOffset",Vector) = (0,0,0,0)
		
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows addshadow 
		#pragma vertex vertFunc

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

		float _HeightMultiplier;
		float _SampleMultiplier;
		sampler2D _HeightMap;

		float2 _VertexMin;
		float2 _VertexMax;
		float2 _UVMin;
		float2 _UVMax;

		float2 _CropSize;
		float2 _CropOffset;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }

		float2 vertexToUV(float4 vertex)
		{			
			return (vertex.xz - _VertexMin) / (_VertexMax - _VertexMin)
				* (_UVMax - _UVMin) + _UVMin;
		}

		float4 getVertex(float4 newVertex)
		{
			float3 normal  = float3(0,1,0);
			float2 texcoord = vertexToUV(newVertex);

			fixed height = tex2Dlod(_HeightMap, float4(texcoord,0,0)).r;
			
			newVertex.xyz  += normal * height  * _HeightMultiplier;	
			return newVertex;
		}

		void vertFunc(inout appdata_base v)
		{			
			float2 croppedMin = _CropOffset;
			float2 croppedMax = croppedMin + _CropSize;

			float4 cropped = v.vertex;
			cropped.xz = (v.vertex.xz - _VertexMin) / (_VertexMax - _VertexMin)
				* (croppedMax - croppedMin) + croppedMin;

			v.vertex.y = getVertex(cropped).y-0.5;
			v.texcoord = float4(vertexToUV(cropped), 0,0);
		}
		
        ENDCG
    }
    FallBack "Diffuse"
}
