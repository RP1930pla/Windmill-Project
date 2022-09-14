using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using System.Collections.Generic;

[System.Serializable]
public class LightShaftsSettings
{
    [Header("Properties")]
    [Range(0.1f, 1f)]
    public float resolutionScale = 0.5f;

    [Range(0.0f, 1.0f)]
    public float intensity = 1.0f;

    [Range(0.0f, 1.0f)]
    public float blurWidth = 0.85f;
}

public class LightShafts : ScriptableRendererFeature
{

    class LightShaftsPass : ScriptableRenderPass
    {

        private readonly List<ShaderTagId> shaderTagIdList = new List<ShaderTagId>();
        private RenderTargetIdentifier cameraColorTargetIdent;


        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.


        // Custom Pass Variables //
        private readonly RenderTargetHandle occluders = RenderTargetHandle.CameraTarget;
        private readonly float resolutionScale;
        private readonly float intensity;
        private readonly float blurWidth;
        private readonly Material occludersmat;
        private readonly Material radialBlurMat;
        


        private FilteringSettings filteringSettings =
        new FilteringSettings(RenderQueueRange.opaque);

        //CONSTRUCTOR//
        public LightShaftsPass(LightShaftsSettings settings)
        {
            occluders.Init("_OccludersMap");
            resolutionScale = settings.resolutionScale;
            intensity = settings.intensity;
            blurWidth = settings.blurWidth;
            occludersmat = new Material(Shader.Find("Unlit/Anima/Occluders_2"));
            radialBlurMat = new Material(Shader.Find("Hidden/Anima/RadialBlur"));

            shaderTagIdList.Add(new ShaderTagId("UniversalForward"));
            shaderTagIdList.Add(new ShaderTagId("UniversalForwardOnly"));
            shaderTagIdList.Add(new ShaderTagId("LightweightForward"));
            shaderTagIdList.Add(new ShaderTagId("SRPDefaultUnlit"));
        }

        public void SetCameraColorTarget(RenderTargetIdentifier cameraColorTargetIdent)
        {
            this.cameraColorTargetIdent = cameraColorTargetIdent;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            RenderTextureDescriptor cameraTextureDescriptor = renderingData.cameraData.cameraTargetDescriptor;

            // Setup depth buffer, disabling it //
            cameraTextureDescriptor.depthBufferBits = 0;

            // Setup Render Texture Resolution //
            cameraTextureDescriptor.width = Mathf.RoundToInt(cameraTextureDescriptor.width * resolutionScale);
            cameraTextureDescriptor.height = Mathf.RoundToInt(cameraTextureDescriptor.height * resolutionScale);

            cmd.GetTemporaryRT(occluders.id, cameraTextureDescriptor, FilterMode.Bilinear);

            ConfigureTarget(occluders.Identifier());
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {

            if (!occludersmat || !radialBlurMat)
            {
                return;
            }

            CommandBuffer cmd = CommandBufferPool.Get();

            // You wrap the graphic commands inside a ProfilingScope, which ensures that FrameDebugger can profile the code. //
            using (new ProfilingScope(cmd, new ProfilingSampler("LightShafts")))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                Camera camera = renderingData.cameraData.camera;
                context.DrawSkybox(camera);

                DrawingSettings drawingSettings = CreateDrawingSettings(shaderTagIdList, ref renderingData, SortingCriteria.CommonOpaque);
                drawingSettings.overrideMaterial = occludersmat;
                context.DrawRenderers(renderingData.cullResults, ref drawingSettings, ref filteringSettings);


                Vector3 sunDirWS = RenderSettings.sun.transform.forward;
                Vector3 CamPosWS = camera.transform.position;
                Vector3 SunPosWS = CamPosWS + sunDirWS;
                Vector3 SunViewS = camera.WorldToViewportPoint(SunPosWS);


                radialBlurMat.SetVector("_Center", new Vector4(SunViewS.x, SunViewS.y, 0, 0));
                radialBlurMat.SetFloat("_Intensity", intensity);
                radialBlurMat.SetFloat("_BlurWidth", blurWidth);

                Blit(cmd, occluders.Identifier(), cameraColorTargetIdent, radialBlurMat);
            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);

        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(occluders.id);
        }
    }


    // CREATE CUSTOM PASS AND SETTINGS //
    LightShaftsPass m_ScriptablePass;
    public LightShaftsSettings settings = new LightShaftsSettings();

    // Invoked when the feature first loads //
    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new LightShaftsPass(settings);
        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
    }



    //AddRenderPasses(): Called every frame, once per camera. You’ll use it to inject your ScriptableRenderPass instances into the ScriptableRenderer.//
    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
        m_ScriptablePass.SetCameraColorTarget(renderer.cameraColorTarget);
    }
}


